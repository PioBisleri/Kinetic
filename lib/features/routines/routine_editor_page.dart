import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/database.dart';
import '../../core/settings/settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/weight_units.dart';
import '../workout/widgets/add_exercise_sheet.dart';
import 'application/routine_providers.dart';
import 'application/routine_repository.dart';

/// Builder for one routine: ordered exercises with per-slot targets,
/// supersets, and warm-ups. Local edits live in state; Save persists
/// the whole plan atomically.
class RoutineEditorPage extends ConsumerStatefulWidget {
  const RoutineEditorPage({super.key, this.routineId});

  final String? routineId; // null = creating

  @override
  ConsumerState<RoutineEditorPage> createState() => _RoutineEditorPageState();
}

class _EntryDraft {
  _EntryDraft({
    required this.uid,
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    required this.warmup,
    required this.linkNext,
    this.weightKg,
  });

  final String uid; // stable key across reorders
  final String exerciseId;
  final String exerciseName;
  int sets;
  int reps;
  double? weightKg; // kg, null = "bring your usual"
  int restSeconds;
  bool warmup;
  bool linkNext; // superset with the entry below
}

class _RoutineEditorPageState extends ConsumerState<RoutineEditorPage> {
  static const _uuid = Uuid();

  final _name = TextEditingController();
  final _entries = <_EntryDraft>[];
  bool _initialized = false;
  bool _saving = false;

  bool get _isNew => widget.routineId == null;

  @override
  void initState() {
    super.initState();
    _initialized = _isNew;
  }

  /// Populate local drafts from the FIRST resolved detail. Runs inside
  /// build without setState: the spinner is showing (no TextField mounted
  /// yet), so writing the controller is listener-safe, and this very build
  /// renders the editor right after. Subsequent rebuilds skip via the flag.
  void _populate(RoutineDetail? detail) {
    if (detail == null) return;
    _name.text = detail.routine.name;
    _entries
      ..clear()
      ..addAll([
        for (final e in detail.entries)
          _EntryDraft(
            uid: _uuid.v4(),
            exerciseId: e.row.exerciseId,
            exerciseName: e.exercise.name,
            sets: e.row.targetSets,
            reps: e.row.targetReps,
            weightKg: e.row.targetWeight,
            restSeconds: e.row.restSeconds,
            warmup: e.row.isWarmup,
            linkNext: false,
          ),
      ]);
    // Restore superset links from durable groups.
    final rows = detail.entries;
    for (var i = 0; i < rows.length - 1; i++) {
      final g = rows[i].row.supersetGroup;
      if (g != null && rows[i + 1].row.supersetGroup == g) {
        _entries[i].linkNext = true;
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _reorder(int oldIndex, int newIndex) {
    // onReorderItem already adjusts newIndex for the removed item.
    setState(() {
      final item = _entries.removeAt(oldIndex);
      _entries.insert(newIndex, item);
    });
  }

  Future<void> _addExercise() async {
    final id = await showAddExerciseSheet(context);
    if (id == null || !mounted) return;
    final db = ref.read(databaseProvider);
    final exercise = await (db.select(db.exercises)
          ..where((e) => e.id.equals(id))
          ..limit(1))
        .getSingleOrNull();
    if (exercise == null || !mounted) return;
    setState(() {
      _entries.add(_EntryDraft(
        uid: _uuid.v4(),
        exerciseId: id,
        exerciseName: exercise.name,
        sets: 3,
        reps: 8,
        restSeconds: 90,
        warmup: false,
        linkNext: false,
      ));
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give your routine a name.')),
      );
      return;
    }
    setState(() => _saving = true);
    await ref.read(routineRepositoryProvider).saveRoutine(
          id: widget.routineId,
          name: name,
          entries: [
            for (final e in _entries)
              RoutineDraft(
                exerciseId: e.exerciseId,
                targetSets: e.sets,
                targetReps: e.reps,
                targetWeight: e.weightKg,
                restSeconds: e.restSeconds,
                isWarmup: e.warmup,
                linkNext: e.linkNext,
              ),
          ],
        );
    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete routine?'),
        content: Text('"${_name.text.trim()}" will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
                foregroundColor: AppColors.heatHot),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref
        .read(routineRepositoryProvider)
        .deleteRoutine(widget.routineId!);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isNew) {
      // watch() = a real element listener, so the underlying drift stream
      // actually flows (reading StreamProvider.future without a listener
      // never resolves in Riverpod 3).
      final async = ref.watch(routineDetailProvider(widget.routineId!));
      if (async.hasValue) {
        if (!_initialized) {
          _populate(async.value);
          _initialized = true;
        }
      } else if (async.hasError) {
        return Scaffold(
          appBar: AppBar(title: const Text('Edit Routine')),
          body: Center(child: Text('Error: ${async.error}')),
        );
      }
    }
    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final unit = ref.watch(settingsProvider).unit;
    final unitLabel = unit == UnitSystem.kg ? 'kg' : 'lb';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'New Routine' : 'Edit Routine'),
        actions: [
          if (!_isNew)
            IconButton(
              key: const Key('routine-delete'),
              tooltip: 'Delete routine',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
          TextButton(
            key: const Key('routine-save'),
            onPressed: _saving ? null : _save,
            child: const Text('Save',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              key: const Key('routine-name'),
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Routine name (e.g. Push Day)',
              ),
            ),
          ),
          Expanded(
            child: _entries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.playlist_add_rounded,
                            size: 44, color: context.textTertiary),
                        const SizedBox(height: 12),
                        Text(
                          'No exercises yet — tap Add Exercise below.',
                          style: TextStyle(color: context.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    onReorderItem: _reorder,
                    children: [
                      for (var i = 0; i < _entries.length; i++)
                        _buildEntry(i, unit, unitLabel),
                    ],
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('add-routine-exercise'),
                  onPressed: _addExercise,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Exercise'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntry(int index, UnitSystem unit, String unitLabel) {
    final e = _entries[index];
    final isLast = index == _entries.length - 1;

    return Container(
      key: ValueKey(e.uid),
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ReorderableDragStartListener(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(Icons.drag_handle,
                          color: context.textTertiary),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e.exerciseName,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    key: Key('remove-entry-${e.exerciseId}'),
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.close,
                        size: 18, color: context.textTertiary),
                    onPressed: () => setState(() => _entries.removeAt(index)),
                  ),
                ],
              ),
              Wrap(
                spacing: 14,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _MiniStepper(
                    label: 'Sets',
                    value: e.sets,
                    minusKey: Key('sets-minus-${e.exerciseId}'),
                    plusKey: Key('sets-plus-${e.exerciseId}'),
                    onMinus: () => setState(
                        () => e.sets = (e.sets - 1).clamp(1, 20)),
                    onPlus: () =>
                        setState(() => e.sets = (e.sets + 1).clamp(1, 20)),
                  ),
                  _MiniStepper(
                    label: 'Reps',
                    value: e.reps,
                    minusKey: Key('reps-minus-${e.exerciseId}'),
                    plusKey: Key('reps-plus-${e.exerciseId}'),
                    onMinus: () => setState(
                        () => e.reps = (e.reps - 1).clamp(1, 100)),
                    onPlus: () =>
                        setState(() => e.reps = (e.reps + 1).clamp(1, 100)),
                  ),
                  SizedBox(
                    width: 108,
                    child: TextFormField(
                      key: Key('target-weight-${e.exerciseId}'),
                      initialValue:
                          e.weightKg != null ? formatWeight(e.weightKg!, unit) : '',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (raw) {
                        final v = double.tryParse(
                            raw.trim().replaceAll(',', '.'));
                        e.weightKg = v == null ? null : displayToKg(v, unit);
                      },
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: 'Weight',
                        hintText: unitLabel,
                        suffixText: unitLabel,
                        suffixStyle: TextStyle(
                            fontSize: 12, color: context.textSecondary),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  if (!isLast)
                    FilterChip(
                      key: Key('superset-${e.exerciseId}'),
                      label: const Text('Superset with next'),
                      selected: e.linkNext,
                      showCheckmark: false,
                      onSelected: (v) => setState(() => e.linkNext = v),
                      selectedColor:
                          AppColors.accent.withValues(alpha: 0.18),
                      labelStyle: TextStyle(
                        color: e.linkNext
                            ? AppColors.accent
                            : context.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: e.linkNext
                            ? AppColors.accent
                            : context.border,
                      ),
                    ),
                  FilterChip(
                    key: Key('warmup-${e.exerciseId}'),
                    label: const Text('Warm-up'),
                    selected: e.warmup,
                    showCheckmark: false,
                    onSelected: (v) => setState(() => e.warmup = v),
                    selectedColor:
                        AppColors.heatWarm.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: e.warmup
                          ? AppColors.heatWarm
                          : context.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: e.warmup
                          ? AppColors.heatWarm
                          : context.border,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStepper extends StatelessWidget {
  const _MiniStepper({
    required this.label,
    required this.value,
    required this.minusKey,
    required this.plusKey,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final int value;
  final Key minusKey;
  final Key plusKey;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 42,
          child: Text(label,
              style:
                  TextStyle(fontSize: 12, color: context.textSecondary)),
        ),
        _btn(Icons.remove, minusKey, onMinus),
        SizedBox(
          width: 26,
          child: Center(
            child: Text('$value',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()])),
          ),
        ),
        _btn(Icons.add, plusKey, onPlus),
      ],
    );
  }

  Widget _btn(IconData icon, Key key, VoidCallback onTap) => SizedBox(
        width: 34,
        height: 34,
        child: IconButton(
          key: key,
          padding: EdgeInsets.zero,
          iconSize: 18,
          onPressed: onTap,
          icon: Icon(icon),
        ),
      );
}
