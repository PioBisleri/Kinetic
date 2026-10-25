import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/database.dart';
import '../../core/ledger/ledger.dart';
import '../../core/settings/settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/rest_format.dart';
import '../../core/utils/weight_units.dart';
import '../../core/widgets/app_dialog.dart';
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
    required this.linkNext,
    this.warmupSets = 0,
    this.dropSets = 0,
    this.failureSets = 0,
    this.weightKg,
  });

  final String uid; // stable key across reorders
  final String exerciseId;
  final String exerciseName;
  int sets; // TOTAL planned sets
  int reps;
  double? weightKg; // kg, null = "bring your usual"

  /// Rest override, or [inheritRestSeconds] = "use Settings".
  int restSeconds;

  int warmupSets;
  int dropSets;
  int failureSets;
  bool linkNext; // superset with the entry below

  /// Working sets = total − the other three types (never below 0).
  int get workingSets =>
      (sets - warmupSets - dropSets - failureSets).clamp(0, sets);

  /// Lowering the total takes the set out of a typed slot first
  /// (failure → drop → warm-up), so working sets survive longest.
  void removeOneTypedSet() {
    if (failureSets > 0) {
      failureSets--;
    } else if (dropSets > 0) {
      dropSets--;
    } else if (warmupSets > 0) {
      warmupSets--;
    }
  }
}

class _RoutineEditorPageState extends ConsumerState<RoutineEditorPage> {
  static const _uuid = Uuid();

  final _name = TextEditingController();
  final _entries = <_EntryDraft>[];
  bool _initialized = false;
  bool _saving = false;
  bool _popping = false;
  String _initialSnapshot = '';

  bool get _isNew => widget.routineId == null;

  int get _totalSets => _entries.fold(0, (sum, entry) => sum + entry.sets);

  int get _workingSets =>
      _entries.fold(0, (sum, entry) => sum + entry.workingSets);

  String _snapshot() {
    final name = _name.text;
    final entries = _entries
        .map(
          (e) =>
              '${e.exerciseId}:${e.sets}:${e.reps}:${e.restSeconds}:${e.warmupSets}:${e.dropSets}:${e.failureSets}:${e.linkNext}',
        )
        .join(',');
    return '$name|$entries';
  }

  bool get _hasChanges => _snapshot() != _initialSnapshot;

  @override
  void initState() {
    super.initState();
    _initialized = _isNew;
    if (_isNew) _initialSnapshot = _snapshot();
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
            warmupSets: e.row.warmupSets,
            dropSets: e.row.dropSets,
            failureSets: e.row.failureSets,
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
    _initialSnapshot = _snapshot();
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
    final exercise =
        await (db.select(db.exercises)
              ..where((e) => e.id.equals(id))
              ..limit(1))
            .getSingleOrNull();
    if (exercise == null || !mounted) return;
    setState(() {
      _entries.add(
        _EntryDraft(
          uid: _uuid.v4(),
          exerciseId: id,
          exerciseName: exercise.name,
          sets: 3,
          reps: 8,
          restSeconds: inheritRestSeconds,
          linkNext: false,
        ),
      );
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      showSnack(context, 'Give your routine a name.');
      return;
    }
    setState(() => _saving = true);
    await ref
        .read(routineRepositoryProvider)
        .saveRoutine(
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
                warmupSets: e.warmupSets,
                dropSets: e.dropSets,
                failureSets: e.failureSets,
                linkNext: e.linkNext,
              ),
          ],
        );
    if (mounted) {
      _popping = true;
      context.pop();
    }
  }

  Future<void> _delete() async {
    final confirmed = await confirmAction(
      context,
      title: 'Delete routine?',
      message: '"${_name.text.trim()}" will be removed.',
      confirmLabel: 'Delete',
      cancelLabel: 'Keep',
      danger: true,
    );
    if (confirmed != true || !mounted) return;
    await ref.read(routineRepositoryProvider).deleteRoutine(widget.routineId!);
    if (mounted) {
      _popping = true;
      context.pop();
    }
  }

  Future<bool> _confirmDiscard() async {
    final confirmed = await confirmAction(
      context,
      title: 'Discard changes?',
      message: 'Your edits to this routine will be lost.',
      confirmLabel: 'Discard',
      cancelLabel: 'Keep editing',
      danger: true,
    );
    return confirmed == true;
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
          appBar: TailBar(
            title: 'Edit Routine',
            showMenu: false,
            leading: const _BackButton(),
          ),
          body: Center(child: Text('Error: ${async.error}')),
        );
      }
    }
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final unit = ref.watch(settingsProvider).unit;
    final unitLabel = unit == UnitSystem.kg ? 'kg' : 'lb';

    return PopScope(
      canPop: !_hasChanges || _popping,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final discard = await _confirmDiscard();
        if (discard && mounted) navigator.pop();
      },
      child: Scaffold(
        appBar: TailBar(
          title: _isNew ? 'New Routine' : 'Edit Routine',
          meta: _isNew ? 'PLAN BUILDER · UNSAVED' : 'PLAN BUILDER · EDITING',
          showMenu: false,
          leading: const _BackButton(),
          actions: [
            if (!_isNew)
              IconButton(
                key: const Key('routine-delete'),
                tooltip: 'Delete routine',
                icon: LedgerGlyph(
                  LedgerGlyphType.trash,
                  size: 18,
                  color: context.textSecondary,
                ),
                onPressed: _delete,
              ),
            TextButton(
              key: const Key('routine-save'),
              onPressed: _saving ? null : _save,
              style: TextButton.styleFrom(
                foregroundColor: context.accent,
                textStyle: AppType.meta.copyWith(
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(_saving ? 'SAVING…' : 'SAVE'),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.x5,
                AppSpace.x1,
                AppSpace.x5,
                AppSpace.x3,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionHead(
                    index: '01',
                    title: 'Identity',
                    meta: 'NAME THE PLAN',
                  ),
                  const SizedBox(height: AppSpace.x3),
                  TextField(
                    key: const Key('routine-name'),
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    style: AppType.h2.copyWith(color: context.textPrimary),
                    decoration: _fieldDecoration(
                      context,
                      hint: 'Routine name (e.g. Push Day)',
                    ),
                  ),
                  const SizedBox(height: AppSpace.x3),
                  _DraftSummary(
                    exercises: _entries.length,
                    sets: _totalSets,
                    working: _workingSets,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _entries.isEmpty
                  ? const _EmptyDraft()
                  : ReorderableListView(
                      buildDefaultDragHandles: false,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.x5,
                        0,
                        AppSpace.x5,
                        AppSpace.x3,
                      ),
                      onReorderItem: _reorder,
                      children: [
                        for (var i = 0; i < _entries.length; i++)
                          _buildEntry(i, unit, unitLabel),
                      ],
                    ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.x5,
                  AppSpace.x2,
                  AppSpace.x5,
                  AppSpace.x3,
                ),
                decoration: BoxDecoration(
                  color: context.background,
                  border: Border(top: BorderSide(color: context.border)),
                ),
                child: PushKey(
                  key: const Key('add-routine-exercise'),
                  label: 'Add Exercise',
                  height: 50,
                  onPressed: _addExercise,
                  icon: LedgerGlyph(
                    LedgerGlyphType.plus,
                    size: 15,
                    strokeWidth: 2,
                    color: onAccent(context.accent),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntry(int index, UnitSystem unit, String unitLabel) {
    final e = _entries[index];
    final isLast = index == _entries.length - 1;
    final number = (index + 1).toString().padLeft(2, '0');

    return Container(
      key: ValueKey(e.uid),
      padding: const EdgeInsets.only(bottom: AppSpace.x3),
      child: LedgerPanel(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
              child: Row(
                children: [
                  ReorderableDragStartListener(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.drag_handle,
                        size: 19,
                        color: context.textTertiary,
                      ),
                    ),
                  ),
                  Text(
                    number,
                    style: AppType.meta.copyWith(color: context.textTertiary),
                  ),
                  const SizedBox(width: AppSpace.x2),
                  Expanded(
                    child: Text(
                      e.exerciseName,
                      style: AppType.h2.copyWith(
                        color: context.textPrimary,
                        fontSize: 19,
                        height: 1.05,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    key: Key('remove-entry-${e.exerciseId}'),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Remove exercise',
                    icon: LedgerGlyph(
                      LedgerGlyphType.close,
                      size: 16,
                      color: context.textTertiary,
                    ),
                    onPressed: () => setState(() => _entries.removeAt(index)),
                  ),
                ],
              ),
            ),
            Rule(),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        'TARGETS',
                        style: AppType.meta.copyWith(
                          color: context.textTertiary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        unitLabel.toUpperCase(),
                        style: AppType.metaSm.copyWith(
                          color: context.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.x2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _TargetStepper(
                          label: 'Sets',
                          value: e.sets,
                          minusKey: Key('sets-minus-${e.exerciseId}'),
                          plusKey: Key('sets-plus-${e.exerciseId}'),
                          onMinus: () => setState(() {
                            e.sets = (e.sets - 1).clamp(1, 20);
                            e.removeOneTypedSet();
                          }),
                          onPlus: () => setState(() {
                            e.sets = (e.sets + 1).clamp(1, 20);
                          }),
                        ),
                      ),
                      Container(width: 1, height: 58, color: context.border),
                      Expanded(
                        child: _TargetStepper(
                          label: 'Reps',
                          value: e.reps,
                          minusKey: Key('reps-minus-${e.exerciseId}'),
                          plusKey: Key('reps-plus-${e.exerciseId}'),
                          onMinus: () => setState(
                            () => e.reps = (e.reps - 1).clamp(1, 100),
                          ),
                          onPlus: () => setState(
                            () => e.reps = (e.reps + 1).clamp(1, 100),
                          ),
                        ),
                      ),
                      Container(width: 1, height: 58, color: context.border),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WEIGHT',
                              style: AppType.metaSm.copyWith(
                                color: context.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              key: Key('target-weight-${e.exerciseId}'),
                              initialValue: e.weightKg != null
                                  ? formatWeight(e.weightKg!, unit)
                                  : '',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              textAlign: TextAlign.center,
                              style: AppType.data.copyWith(
                                color: context.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              onChanged: (raw) {
                                final v = double.tryParse(
                                  raw.trim().replaceAll(',', '.'),
                                );
                                e.weightKg = v == null
                                    ? null
                                    : displayToKg(v, unit);
                              },
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: '—',
                                suffixText: unitLabel,
                                suffixStyle: AppType.metaSm.copyWith(
                                  color: context.textTertiary,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.input,
                                  ),
                                  borderSide: BorderSide(color: context.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.input,
                                  ),
                                  borderSide: BorderSide(color: context.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.input,
                                  ),
                                  borderSide: BorderSide(color: context.accent),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Rule(),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        'SET TYPES',
                        style: AppType.meta.copyWith(
                          color: context.textTertiary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${e.workingSets} working',
                        style: AppType.metaSm.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.x2),
                  Wrap(
                    spacing: 14,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _MiniStepper(
                        label: 'Warm-up',
                        labelWidth: 56,
                        value: e.warmupSets,
                        minusKey: Key('warmup-minus-${e.exerciseId}'),
                        plusKey: Key('warmup-plus-${e.exerciseId}'),
                        onMinus: () => setState(
                          () => e.warmupSets = (e.warmupSets - 1).clamp(
                            0,
                            e.workingSets + e.warmupSets,
                          ),
                        ),
                        onPlus: () => setState(
                          () => e.warmupSets = (e.warmupSets + 1).clamp(
                            0,
                            e.sets - e.dropSets - e.failureSets,
                          ),
                        ),
                      ),
                      _MiniStepper(
                        label: 'Drop',
                        value: e.dropSets,
                        minusKey: Key('drop-minus-${e.exerciseId}'),
                        plusKey: Key('drop-plus-${e.exerciseId}'),
                        onMinus: () => setState(
                          () => e.dropSets = (e.dropSets - 1).clamp(
                            0,
                            e.workingSets + e.dropSets,
                          ),
                        ),
                        onPlus: () => setState(
                          () => e.dropSets = (e.dropSets + 1).clamp(
                            0,
                            e.sets - e.warmupSets - e.failureSets,
                          ),
                        ),
                      ),
                      _MiniStepper(
                        label: 'Fail',
                        value: e.failureSets,
                        minusKey: Key('failure-minus-${e.exerciseId}'),
                        plusKey: Key('failure-plus-${e.exerciseId}'),
                        onMinus: () => setState(
                          () => e.failureSets = (e.failureSets - 1).clamp(
                            0,
                            e.workingSets + e.failureSets,
                          ),
                        ),
                        onPlus: () => setState(
                          () => e.failureSets = (e.failureSets + 1).clamp(
                            0,
                            e.sets - e.warmupSets - e.dropSets,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Rule(),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (!isLast)
                    _LedgerToggle(
                      key: Key('superset-${e.exerciseId}'),
                      label: 'Superset with next',
                      selected: e.linkNext,
                      onTap: () => setState(() => e.linkNext = !e.linkNext),
                    ),
                  _RestControl(
                    id: 'rest-${e.exerciseId}',
                    restSeconds: e.restSeconds,
                    defaultSeconds: ref.read(settingsProvider).restWorkingSec,
                    onChanged: (v) => setState(() => e.restSeconds = v),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      onPressed: () => Navigator.of(context).maybePop(),
      icon: LedgerGlyph(
        LedgerGlyphType.chevronLeft,
        size: 18,
        color: context.textPrimary,
      ),
    );
  }
}

class _DraftSummary extends StatelessWidget {
  const _DraftSummary({
    required this.exercises,
    required this.sets,
    required this.working,
  });

  final int exercises;
  final int sets;
  final int working;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.x3, vertical: 9),
      decoration: BoxDecoration(
        color: context.surface,
        border: Border.all(color: context.border),
        borderRadius: BorderRadius.circular(AppRadius.data),
      ),
      child: Row(
        children: [
          Text(
            '$exercises EX',
            style: AppType.metaSm.copyWith(color: context.textSecondary),
          ),
          const SizedBox(width: AppSpace.x3),
          Text(
            '$sets SETS',
            style: AppType.metaSm.copyWith(color: context.textSecondary),
          ),
          const SizedBox(width: AppSpace.x3),
          Text(
            '$working WORKING',
            style: AppType.metaSm.copyWith(color: context.textTertiary),
          ),
          const Spacer(),
          Text(
            'DRAG TO REORDER',
            style: AppType.metaSm.copyWith(color: context.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _EmptyDraft extends StatelessWidget {
  const _EmptyDraft();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.x5,
        0,
        AppSpace.x5,
        AppSpace.x5,
      ),
      children: [
        LedgerPanel(
          grid: true,
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '00',
                style: AppType.meta.copyWith(color: context.textTertiary),
              ),
              const SizedBox(height: AppSpace.x2),
              Text(
                'No exercises yet',
                style: AppType.h2.copyWith(color: context.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap Add Exercise below to start writing the plan.',
                style: AppType.bodySm.copyWith(color: context.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TargetStepper extends StatelessWidget {
  const _TargetStepper({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppType.metaSm.copyWith(color: context.textTertiary),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SmallStepButton(key: minusKey, icon: Icons.remove, onTap: onMinus),
            SizedBox(
              width: 28,
              child: Center(
                child: Text(
                  '$value',
                  style: AppType.data.copyWith(
                    color: context.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            _SmallStepButton(key: plusKey, icon: Icons.add, onTap: onPlus),
          ],
        ),
      ],
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
    this.labelWidth = 42,
  });

  final String label;
  final int value;
  final Key minusKey;
  final Key plusKey;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(
            label,
            style: AppType.metaSm.copyWith(color: context.textSecondary),
          ),
        ),
        _SmallStepButton(key: minusKey, icon: Icons.remove, onTap: onMinus),
        SizedBox(
          width: 26,
          child: Center(
            child: Text(
              '$value',
              style: AppType.data.copyWith(
                color: context.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        _SmallStepButton(key: plusKey, icon: Icons.add, onTap: onPlus),
      ],
    );
  }
}

class _SmallStepButton extends StatelessWidget {
  const _SmallStepButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 15,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
        style: IconButton.styleFrom(
          backgroundColor: context.surfaceElevated,
          foregroundColor: context.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.data),
            side: BorderSide(color: context.border),
          ),
        ),
        onPressed: onTap,
        icon: Icon(icon),
      ),
    );
  }
}

class _LedgerToggle extends StatelessWidget {
  const _LedgerToggle({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? context.accent.withValues(alpha: 0.10)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: context.accent.withValues(alpha: 0.06),
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(
                color: selected ? context.accent : context.border,
              ),
              borderRadius: BorderRadius.circular(AppRadius.data),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: selected ? context.accent : Colors.transparent,
                    border: Border.all(
                      color: selected ? context.accent : context.textTertiary,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: AppType.metaSm.copyWith(
                    color: selected ? context.accent : context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rest override for one routine entry: a "Default" chip plus −/+ steppers
/// (15 s steps). Chip ON = [inheritRestSeconds] → exercise → Settings.
class _RestControl extends StatelessWidget {
  const _RestControl({
    required this.id,
    required this.restSeconds,
    required this.defaultSeconds,
    required this.onChanged,
  });

  final String id;
  final int restSeconds;
  final int defaultSeconds;
  final ValueChanged<int> onChanged;

  bool get _isDefault => restSeconds == inheritRestSeconds;

  @override
  Widget build(BuildContext context) {
    final value = _isDefault ? defaultSeconds : restSeconds;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilterChip(
          key: Key('$id-default'),
          label: const Text('Default rest'),
          selected: _isDefault,
          showCheckmark: false,
          onSelected: (v) {
            if (v) {
              onChanged(inheritRestSeconds);
            } else {
              onChanged(defaultSeconds.clamp(0, 600));
            }
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.data),
            side: BorderSide(
              color: _isDefault ? context.accent : context.border,
            ),
          ),
          selectedColor: context.accent.withValues(alpha: 0.10),
          backgroundColor: Colors.transparent,
          labelStyle: AppType.metaSm.copyWith(
            color: _isDefault ? context.accent : context.textSecondary,
          ),
        ),
        if (!_isDefault) ...[
          const SizedBox(width: 4),
          Text(
            formatRest(restSeconds),
            key: Key('$id-value'),
            style: AppType.metaSm.copyWith(color: context.textSecondary),
          ),
          _SmallStepButton(
            key: Key('$id-minus'),
            icon: Icons.remove,
            onTap: () => onChanged((value - 15).clamp(0, 600)),
          ),
          _SmallStepButton(
            key: Key('$id-plus'),
            icon: Icons.add,
            onTap: () => onChanged((value + 15).clamp(0, 600)),
          ),
        ],
      ],
    );
  }
}

InputDecoration _fieldDecoration(
  BuildContext context, {
  required String hint,
}) => InputDecoration(
  hintText: hint,
  hintStyle: AppType.h2.copyWith(color: context.textTertiary),
  filled: true,
  fillColor: context.surface,
  contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.input),
    borderSide: BorderSide(color: context.border),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.input),
    borderSide: BorderSide(color: context.border),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.input),
    borderSide: BorderSide(color: context.accent),
  ),
);
