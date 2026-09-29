import 'dart:convert';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/database.dart';
import '../../core/database/database_providers.dart';
import '../../core/settings/settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/rest_format.dart';
import '../../core/utils/weight_units.dart';
import '../workout/widgets/add_exercise_sheet.dart';

/// Display parents (see seed `groups`) — every other muscle row is a
/// loggable leaf. `chest` is a leaf despite also being a group id, so it
/// stays selectable.
const _groupIds = {'back', 'shoulders', 'arms', 'core', 'legs'};

const _categories = [
  ('barbell', 'Barbell'),
  ('dumbbell', 'Dumbbell'),
  ('machine', 'Machine'),
  ('cable', 'Cable'),
  ('bodyweight', 'Bodyweight'),
  ('cardio', 'Cardio'),
  ('custom', 'Custom'),
];

const List<(String?, String)> _forceOptions = [
  (null, 'None'),
  ('push', 'Push'),
  ('pull', 'Pull'),
  ('static', 'Static'),
];

/// Create (exerciseId == null) or edit a user-defined exercise.
class ExerciseEditPage extends ConsumerStatefulWidget {
  const ExerciseEditPage({super.key, this.exerciseId});

  final String? exerciseId;

  @override
  ConsumerState<ExerciseEditPage> createState() => _ExerciseEditPageState();
}

class _ExerciseEditPageState extends ConsumerState<ExerciseEditPage> {
  static const _uuid = Uuid();

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _equipmentCtrl = TextEditingController();

  String _category = 'custom';
  String _mechanics = 'compound';
  String? _force;
  String? _primaryId;
  String _metric = 'weight_reps';
  Set<String> _secondary = <String>{};

  /// Rest override for this exercise; null = use the Settings default.
  int? _restSec;

  /// Progression step override in kg; null = use the unit default
  /// (2.5 kg / 5 lb).
  double? _incrementKg;

  /// Per-muscle share of set volume for each secondary muscle (0–1,
  /// default 0.4). The primary muscle is always 1.0.
  final Map<String, double> _contributions = {};
  bool _showPrimaryError = false;
  bool _dirty = false;

  bool get _isEdit => widget.exerciseId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _loadExisting();
    } else {
      final prefill = exerciseNamePrefill;
      if (prefill != null && prefill.isNotEmpty) {
        _nameCtrl.text = prefill;
        _dirty = true;
        exerciseNamePrefill = null;
      }
    }
    _nameCtrl.addListener(_markDirty);
    _equipmentCtrl.addListener(_markDirty);
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _equipmentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    final db = ref.read(databaseProvider);
    final exercise = await (db.select(db.exercises)
          ..where((e) => e.id.equals(widget.exerciseId!)))
        .getSingleOrNull();
    if (exercise == null || !mounted) return;
    final mapRows = await (db.select(db.exerciseMuscleMap)
          ..where((m) => m.exerciseId.equals(exercise.id)))
        .get();
    if (!mounted) return;
    setState(() {
      _nameCtrl.text = exercise.name;
      _category = exercise.category;
      _mechanics = exercise.mechanics;
      _force = exercise.forceType;
      _primaryId = exercise.primaryMuscleId;
      _metric = exercise.defaultMetric;
      _restSec = exercise.restSeconds;
      _incrementKg = exercise.progressionIncrementKg;
      _equipmentCtrl.text =
          (jsonDecode(exercise.equipment) as List).cast<String>().join(', ');
      _secondary = {
        for (final row in mapRows)
          if (row.muscleId != exercise.primaryMuscleId) row.muscleId,
      };
      _contributions
        ..clear()
        ..addAll({
          for (final row in mapRows) row.muscleId: row.contribution,
        });
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final name = _nameCtrl.text.trim();
    final primary = _primaryId;
    if (primary == null) {
      setState(() => _showPrimaryError = true);
      return;
    }

    final db = ref.read(databaseProvider);
    final now = DateTime.now().toUtc();
    final equipment = jsonEncode([
      for (final part in _equipmentCtrl.text.split(','))
        if (part.trim().isNotEmpty) part.trim(),
    ]);
    final secondary = {
      for (final id in _secondary)
        if (id != primary) id: (_contributions[id] ?? 0.4).clamp(0.0, 1.0).toDouble(),
    };

    if (!_isEdit) {
      final id = 'cus_${_uuid.v4()}';
      await db.transaction(() async {
        await db.into(db.exercises).insert(
              ExercisesCompanion.insert(
                id: id,
                name: name,
                mechanics: _mechanics,
                forceType: Value(_force),
                category: Value(_category),
                primaryMuscleId: primary,
                equipment: Value(equipment),
                defaultMetric: Value(_metric),
                isCustom: const Value(true),
                ownerId: const Value('local'),
                restSeconds: Value(_restSec),
                progressionIncrementKg: Value(_incrementKg),
                updatedAt: now,
              ),
            );
        await _writeMuscleMap(db, id, primary, secondary);
      });
    } else {
      await db.transaction(() async {
        await (db.update(db.exercises)
              ..where((e) => e.id.equals(widget.exerciseId!)))
            .write(ExercisesCompanion(
          name: Value(name),
          mechanics: Value(_mechanics),
          forceType: Value(_force),
          category: Value(_category),
          primaryMuscleId: Value(primary),
          equipment: Value(equipment),
          defaultMetric: Value(_metric),
          restSeconds: Value(_restSec),
          progressionIncrementKg: Value(_incrementKg),
          updatedAt: Value(now),
        ));
        await (db.delete(db.exerciseMuscleMap)
              ..where((m) => m.exerciseId.equals(widget.exerciseId!)))
            .go();
        await _writeMuscleMap(db, widget.exerciseId!, primary, secondary);
      });
    }
    if (mounted) {
      _dirty = false;
      context.pop();
    }
  }

  Future<void> _writeMuscleMap(
    AppDatabase db,
    String exerciseId,
    String primary,
    Map<String, double> secondaryContributions,
  ) async {
    await db.into(db.exerciseMuscleMap).insert(
          ExerciseMuscleMapCompanion.insert(
            exerciseId: exerciseId,
            muscleId: primary,
            contribution: const Value(1.0),
            role: const Value('primary'),
          ),
        );
    for (final entry in secondaryContributions.entries) {
      await db.into(db.exerciseMuscleMap).insert(
            ExerciseMuscleMapCompanion.insert(
              exerciseId: exerciseId,
              muscleId: entry.key,
              contribution: Value(entry.value),
              role: const Value('secondary'),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final muscles = ref.watch(musclesProvider);
    final unit = ref.watch(settingsProvider).unit;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final discard = await _confirmDiscard();
        if (discard && mounted) navigator.pop();
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Exercise' : 'New Exercise'),
        actions: [
          TextButton(
            key: const Key('exercise-save'),
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: muscles.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (all) {
          final leaves =
              all.where((m) => !_groupIds.contains(m.id)).toList();
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              children: [
                TextFormField(
                  key: const Key('exercise-name'),
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                _DropdownField<String>(
                  key: const Key('exercise-category'),
                  label: 'Category',
                  value: _category,
                  items: [
                    for (final (id, label) in _categories)
                      DropdownMenuItem(value: id, child: Text(label)),
                  ],
                  onChanged: (v) => setState(() {
                    _category = v ?? 'custom';
                    _dirty = true;
                  }),
                ),
                const SizedBox(height: 20),
                const _SectionLabel('Type'),
                SegmentedButton<String>(
                  key: const Key('exercise-mechanics'),
                  segments: const [
                    ButtonSegment(value: 'compound', label: Text('Compound')),
                    ButtonSegment(value: 'isolation', label: Text('Isolation')),
                  ],
                  selected: {_mechanics},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() {
                    _mechanics = s.first;
                    _dirty = true;
                  }),
                ),
                const SizedBox(height: 12),
                _DropdownField<String?>(
                  key: const Key('exercise-force'),
                  label: 'Force pattern',
                  value: _force,
                  items: [
                    for (final (id, label) in _forceOptions)
                      DropdownMenuItem<String?>(
                        value: id,
                        child: Text(label),
                      ),
                  ],
                  onChanged: (v) => setState(() {
                    _force = v;
                    _dirty = true;
                  }),
                ),
                const SizedBox(height: 20),
                const _SectionLabel('Primary muscle'),
                _DropdownField<String>(
                  key: const Key('exercise-primary'),
                  label: 'Primary',
                  hint: 'Select muscle',
                  value: _primaryId,
                  items: [
                    for (final m in leaves)
                      DropdownMenuItem(value: m.id, child: Text(m.name)),
                  ],
                  onChanged: (v) => setState(() {
                    _primaryId = v;
                    _showPrimaryError = false;
                    _dirty = true;
                  }),
                ),
                if (_showPrimaryError && _primaryId == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'Primary muscle required',
                      style: TextStyle(fontSize: 12, color: Colors.redAccent),
                    ),
                  ),
                const SizedBox(height: 20),
                const _SectionLabel('Secondary muscles'),
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Each secondary’s share of set volume (default 40%).',
                    style: TextStyle(fontSize: 12, color: context.textTertiary),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final m in leaves)
                      if (m.id != _primaryId)
                        FilterChip(
                          key: Key('muscle-${m.id}'),
                          label: Text(m.name),
                          selected: _secondary.contains(m.id),
                          onSelected: (selected) => setState(() {
                            if (selected) {
                              _secondary.add(m.id);
                              _contributions.putIfAbsent(m.id, () => 0.4);
                            } else {
                              _secondary.remove(m.id);
                            }
                            _dirty = true;
                          }),
                          selectedColor:
                              AppColors.accent.withValues(alpha: 0.18),
                          checkmarkColor: AppColors.accent,
                        ),
                  ],
                ),
                if (_secondary.isNotEmpty)
                  for (final m in leaves)
                    if (m.id != _primaryId && _secondary.contains(m.id))
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                m.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: context.textSecondary),
                              ),
                            ),
                            SizedBox(
                              width: 150,
                              child: Slider(
                                key: Key('contribution-slider-${m.id}'),
                                value: (_contributions[m.id] ?? 0.4)
                                    .clamp(0.0, 1.0)
                                    .toDouble(),
                                divisions: 100,
                                onChanged: (v) => setState(
                                  () => _contributions[m.id] =
                                      (v * 100).roundToDouble() / 100,
                                ),
                                // Slider drags fire many setState calls; mark
                                // dirty on the first one only.
                                onChangeStart: (_) => _markDirty(),
                              ),
                            ),
                            SizedBox(
                              width: 44,
                              child: Text(
                                '${((_contributions[m.id] ?? 0.4) * 100).round()}%',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                const SizedBox(height: 20),
                TextFormField(
                  key: const Key('exercise-equipment'),
                  controller: _equipmentCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Equipment',
                    hintText: 'barbell, bench',
                  ),
                ),
                const SizedBox(height: 20),
                const _SectionLabel('How it’s logged'),
                SegmentedButton<String>(
                  key: const Key('exercise-metric'),
                  segments: const [
                    ButtonSegment(value: 'weight_reps', label: Text('Weight')),
                    ButtonSegment(value: 'duration', label: Text('Duration')),
                    ButtonSegment(value: 'distance', label: Text('Distance')),
                  ],
                  selected: {_metric},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() {
                    _metric = s.first;
                    _dirty = true;
                  }),
                ),
                const SizedBox(height: 20),
                const _SectionLabel('Rest between sets'),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      FilterChip(
                        key: const Key('exercise-rest-default'),
                        label: const Text('Default'),
                        selected: _restSec == null,
                        onSelected: (useDefault) {
                          final seed = _restSec ??
                              ref.read(settingsProvider).restWorkingSec;
                          setState(() {
                            _restSec = useDefault ? null : seed;
                            _dirty = true;
                          });
                        },
                        selectedColor:
                            AppColors.accent.withValues(alpha: 0.18),
                        checkmarkColor: AppColors.accent,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _restSec == null
                              ? 'Uses Settings default'
                              : formatRest(_restSec!),
                          key: const Key('exercise-rest-value'),
                          style: TextStyle(
                              fontSize: 13, color: context.textTertiary),
                        ),
                      ),
                      IconButton(
                        key: const Key('exercise-rest-minus'),
                        icon: const Icon(Icons.remove, size: 18),
                        onPressed: () {
                          final base = _restSec ??
                              ref.read(settingsProvider).restWorkingSec;
                          setState(() {
                            _restSec = (base - 15).clamp(0, 600);
                            _dirty = true;
                          });
                        },
                      ),
                      IconButton(
                        key: const Key('exercise-rest-plus'),
                        icon: const Icon(Icons.add, size: 18),
                        onPressed: () {
                          final base = _restSec ??
                              ref.read(settingsProvider).restWorkingSec;
                          setState(() {
                            _restSec = (base + 15).clamp(0, 600);
                            _dirty = true;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_metric == 'weight_reps') ...[
                  const _SectionLabel('Load increment'),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        FilterChip(
                          key: const Key('exercise-increment-default'),
                          label: const Text('Default'),
                          selected: _incrementKg == null,
                          onSelected: (useDefault) {
                            final seed = _incrementKg ?? stepKg(unit);
                            setState(() {
                              _incrementKg = useDefault ? null : seed;
                              _dirty = true;
                            });
                          },
                          selectedColor:
                              AppColors.accent.withValues(alpha: 0.18),
                          checkmarkColor: AppColors.accent,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _incrementKg == null
                                ? 'Uses ${formatWeight(stepKg(unit), unit)} '
                                    '${unitLabel(unit)} default'
                                : '${formatWeight(_incrementKg!, unit)} '
                                    '${unitLabel(unit)}',
                            key: const Key('exercise-increment-value'),
                            style: TextStyle(
                                fontSize: 13, color: context.textTertiary),
                          ),
                        ),
                        IconButton(
                          key: const Key('exercise-increment-minus'),
                          icon: const Icon(Icons.remove, size: 18),
                          onPressed: () {
                            final base = kgToDisplay(
                                _incrementKg ?? stepKg(unit), unit);
                            final floor =
                                unit == UnitSystem.kg ? 0.25 : 0.5;
                            final next =
                                (base - (unit == UnitSystem.kg ? 0.5 : 1))
                                    .clamp(floor, 40)
                                    .toDouble();
                            setState(() {
                              _incrementKg = displayToKg(next, unit);
                              _dirty = true;
                            });
                          },
                        ),
                        IconButton(
                          key: const Key('exercise-increment-plus'),
                          icon: const Icon(Icons.add, size: 18),
                          onPressed: () {
                            final base = kgToDisplay(
                                _incrementKg ?? stepKg(unit), unit);
                            final floor =
                                unit == UnitSystem.kg ? 0.25 : 0.5;
                            final next =
                                (base + (unit == UnitSystem.kg ? 0.5 : 1))
                                    .clamp(floor, 40)
                                    .toDouble();
                            setState(() {
                              _incrementKg = displayToKg(next, unit);
                              _dirty = true;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    ),
    );
  }

  Future<bool> _confirmDiscard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'Your edits to this exercise will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.heatHot,
              minimumSize: const Size(0, 44),
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: context.textSecondary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// Labelled dropdown: a plain [DropdownButton] in an [InputDecorator] —
/// unlike `DropdownButtonFormField.value` (deprecated), the value stays
/// externally controlled, so async loads update the display immediately.
class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final String? hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: hint == null ? null : Text(hint!),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
