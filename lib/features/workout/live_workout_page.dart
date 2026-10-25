import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/database.dart';
import '../../core/ledger/ledger.dart';
import '../../core/settings/settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/weight_units.dart';
import '../../core/widgets/app_dialog.dart';
import 'application/rest_resolver.dart';
import 'application/workout_session_notifier.dart';
import 'widgets/add_exercise_sheet.dart';
import 'widgets/rest_timer_bar.dart';
import 'widgets/set_edit_sheet.dart';

/// The frictionless live logger: big targets, one-tap set logging,
/// auto rest timer. Pushed as a full-screen route (no bottom nav).
class LiveWorkoutPage extends ConsumerStatefulWidget {
  const LiveWorkoutPage({super.key});

  @override
  ConsumerState<LiveWorkoutPage> createState() => _LiveWorkoutPageState();
}

class _LiveWorkoutPageState extends ConsumerState<LiveWorkoutPage> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _finish(WorkoutSession session) async {
    final pending = session.sets.where((s) => !s.isCompleted).length;
    // Only completed sets land in history — warn before the user loses a
    // routine's unchecked planned sets.
    final warning = pending == 0
        ? ''
        : '\n\n⚠️ $pending planned set${pending == 1 ? '' : 's'} not '
              'checked — they will NOT be saved to your history.';
    final confirmed = await confirmAction(
      context,
      title: 'Finish workout?',
      message:
          '${session.exercises.length} exercises · '
          '${session.completedSetCount} sets · '
          '${formatElapsed(session.elapsed)}\n'
          'Volume: ${session.volumeKg.toStringAsFixed(0)} kg'
          '$warning',
      confirmLabel: pending > 0 ? 'Finish anyway' : 'Finish',
      cancelLabel: 'Keep going',
    );
    if (confirmed != true || !mounted) return;
    await ref.read(workoutSessionProvider.notifier).finishWorkout();
    if (mounted) context.pop();
  }

  Future<void> _discard(WorkoutSession? session) async {
    if (session == null) return;
    final confirmed = await confirmAction(
      context,
      title: 'Discard workout?',
      message:
          '${session.exercises.length} exercises · '
          '${session.completedSetCount} sets · '
          'Volume: ${session.volumeKg.toStringAsFixed(0)} kg\n\n'
          'Nothing will be saved to your history. This cannot be undone.',
      confirmLabel: 'Discard',
      cancelLabel: 'Keep workout',
      danger: true,
    );
    if (confirmed != true || !mounted) return;
    await ref.read(workoutSessionProvider.notifier).discardWorkout();
    if (mounted) context.pop();
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    Exercise exercise,
    WorkoutSession session,
  ) async {
    final sets = session.setsFor(exercise.id);
    final completed = sets.where((s) => s.isCompleted).length;
    final confirmed = await confirmAction(
      context,
      title: 'Remove ${exercise.name}?',
      message: sets.isEmpty
          ? 'This exercise has no sets yet.'
          : '${sets.length} set${sets.length == 1 ? '' : 's'} '
                '($completed completed) will be deleted from this workout.',
      confirmLabel: 'Remove',
      danger: true,
    );
    if (confirmed != true || !mounted) return;
    await ref.read(workoutSessionProvider.notifier).removeExercise(exercise.id);
  }

  Future<void> _editNotes(WorkoutSession session) async {
    final controller = TextEditingController(text: session.workout.notes ?? '');
    final result = await showAppSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Workout notes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 5,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Felt strong today, bench moved fast…',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(controller.text),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null) {
      await ref.read(workoutSessionProvider.notifier).saveWorkoutNotes(result);
    }
  }

  Future<void> _addExercise() async {
    final id = await showAddExerciseSheet(context);
    if (id != null) {
      await ref.read(workoutSessionProvider.notifier).addExercise(id);
    }
  }

  /// Log a brand-new set via the editor, then auto-start the rest timer.
  Future<void> _logSet(Exercise exercise, WorkoutSession session) async {
    final all = session.setsFor(exercise.id);
    final last = all.isEmpty ? null : all.last;
    final result = await showSetEditSheet(
      context,
      exercise: exercise,
      initial: last != null
          ? SetDraft(
              weightKg: last.weightKg,
              reps: last.reps,
              rpe: last.rpe,
              setType: last.setType,
              distanceM: last.distanceM,
              durationSec: last.durationSec,
            )
          : null,
    );
    if (result is! SetDraft || !mounted) return;

    final notifier = ref.read(workoutSessionProvider.notifier);
    if (result.isEmptyValues) return;
    final logged = await notifier.logSet(
      exerciseId: exercise.id,
      setType: result.setType,
      weightKg: result.weightKg,
      reps: result.reps,
      rpe: result.rpe,
      distanceM: result.distanceM,
      durationSec: result.durationSec,
      heartRate: result.heartRate,
    );

    HapticFeedback.mediumImpact();
    if (mounted) {
      showSnack(
        context,
        'Set logged',
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => notifier.deleteSet(logged.id),
        ),
      );
    }

    final rest = await resolveRestSeconds(
      db: ref.read(databaseProvider),
      settings: ref.read(settingsProvider),
      session: session,
      exerciseId: exercise.id,
      setType: result.setType,
    );
    if (rest > 0 && mounted) {
      ref.read(restTimerProvider.notifier).start(rest);
    }
  }

  Future<void> _editSet(
    WorkoutSession session,
    Exercise exercise,
    WorkoutSet set,
    int number,
  ) async {
    final result = await showSetEditSheet(
      context,
      exercise: exercise,
      setNumber: number,
      initial: SetDraft(
        weightKg: set.weightKg,
        reps: set.reps,
        rpe: set.rpe,
        setType: set.setType,
        distanceM: set.distanceM,
        durationSec: set.durationSec,
      ),
    );
    if (!mounted) return;
    final notifier = ref.read(workoutSessionProvider.notifier);
    if (result == 'delete') {
      await notifier.deleteSet(set.id);
    } else if (result is SetDraft) {
      final wasPlanned = !set.isCompleted;
      await notifier.updateSet(
        set.id,
        setType: result.setType,
        weightKg: result.weightKg,
        reps: result.reps,
        rpe: result.rpe,
        distanceM: result.distanceM,
        durationSec: result.durationSec,
        complete: true,
      );
      // Completing a routine's planned set starts the rest period.
      if (wasPlanned && mounted) {
        final rest = await resolveRestSeconds(
          db: ref.read(databaseProvider),
          settings: ref.read(settingsProvider),
          session: session,
          exerciseId: exercise.id,
          setType: result.setType,
        );
        if (rest > 0) ref.read(restTimerProvider.notifier).start(rest);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(workoutSessionProvider);
    final unit = ref.watch(settingsProvider).unit;
    final title = sessionAsync.when(
      data: (s) => s == null ? 'Workout' : formatElapsed(s.elapsed),
      loading: () => 'Workout',
      error: (_, _) => 'Workout',
    );

    return Scaffold(
      appBar: TailBar(
        title: title,
        meta: 'LIVE SESSION',
        showMenu: false,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: LedgerGlyph(
            LedgerGlyphType.chevronLeft,
            size: 18,
            color: context.textPrimary,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'More',
            icon: Icon(Icons.more_vert, size: 20, color: context.textSecondary),
            enabled: sessionAsync.value != null,
            onSelected: (value) {
              if (value == 'discard') _discard(sessionAsync.value);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'discard', child: Text('Discard workout')),
            ],
          ),
          IconButton(
            tooltip: 'Notes',
            icon: LedgerGlyph(
              LedgerGlyphType.edit,
              size: 18,
              color: context.textSecondary,
            ),
            onPressed: sessionAsync.value == null
                ? null
                : () => _editNotes(sessionAsync.value!),
          ),
          TextButton(
            onPressed: sessionAsync.value == null
                ? null
                : () => _finish(sessionAsync.value!),
            style: TextButton.styleFrom(
              foregroundColor: context.accent,
              textStyle: AppType.meta.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Finish'),
          ),
        ],
      ),
      body: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (session) {
          if (session == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No active workout.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.pop(),
                    child: const Text('Back'),
                  ),
                ],
              ),
            );
          }
          if (session.exercises.isEmpty) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.x5,
                AppSpace.x1,
                AppSpace.x5,
                AppSpace.x8,
              ),
              children: [
                _SessionSummary(session: session, unit: unit),
                const SizedBox(height: AppSpace.x5),
                _EmptySession(onAdd: _addExercise),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.x5,
              AppSpace.x1,
              AppSpace.x5,
              AppSpace.x8,
            ),
            children: [
              _SessionSummary(session: session, unit: unit),
              const SizedBox(height: AppSpace.x5),
              SectionHead(
                index: '01',
                title: 'Exercise log',
                meta: '${session.exercises.length} EXERCISES',
              ),
              const SizedBox(height: AppSpace.x3),
              for (var i = 0; i < session.exercises.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.x3),
                  child: _ExercisePanel(
                    key: ValueKey(session.exercises[i].id),
                    index: i,
                    exercise: session.exercises[i],
                    session: session,
                    unit: unit,
                    onAddSet: () => _logSet(session.exercises[i], session),
                    onEditSet: (set, number) =>
                        _editSet(session, session.exercises[i], set, number),
                    onSupersetNext: () => ref
                        .read(workoutSessionProvider.notifier)
                        .supersetWithNext(session.exercises[i].id),
                    onRemove: () => _confirmRemove(
                      context,
                      ref,
                      session.exercises[i],
                      session,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpace.x1),
              OutlinedButton.icon(
                key: const Key('add-exercise'),
                onPressed: _addExercise,
                style: _outlineStyle(context),
                icon: LedgerGlyph(
                  LedgerGlyphType.plus,
                  size: 14,
                  color: context.textSecondary,
                ),
                label: const Text('Add Exercise'),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const RestTimerBar(),
    );
  }
}

class _SessionSummary extends StatelessWidget {
  const _SessionSummary({required this.session, required this.unit});

  final WorkoutSession session;
  final UnitSystem unit;

  @override
  Widget build(BuildContext context) {
    final totalSets = session.sets.length;
    final progress = totalSets == 0
        ? 0.0
        : session.completedSetCount / totalSets;
    final volume = unit == UnitSystem.kg
        ? '${session.volumeKg.toStringAsFixed(0)} kg'
        : '${formatWeight(session.volumeKg, unit)} lb';

    return LedgerPanel(
      accentTop: true,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(width: 6, height: 6, color: context.signal),
              const SizedBox(width: 8),
              Text(
                'IN PROGRESS',
                style: AppType.meta.copyWith(color: context.signal),
              ),
              const Spacer(),
              Text(
                formatElapsed(session.elapsed),
                style: AppType.data.copyWith(
                  color: context.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.x4),
          Row(
            children: [
              _LiveStat(
                value: session.exercises.length.toString().padLeft(2, '0'),
                label: 'EXERCISES',
              ),
              Container(width: 1, height: 38, color: context.border),
              _LiveStat(
                value:
                    '${session.completedSetCount.toString().padLeft(2, '0')}/'
                    '${totalSets.toString().padLeft(2, '0')}',
                label: 'SETS',
              ),
              Container(width: 1, height: 38, color: context.border),
              _LiveStat(value: volume, label: 'VOLUME'),
            ],
          ),
          const SizedBox(height: AppSpace.x3),
          ProgressRule(value: progress, segments: 18, height: 6),
        ],
      ),
    );
  }
}

class _LiveStat extends StatelessWidget {
  const _LiveStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppType.dataLg.copyWith(
              color: context.textPrimary,
              height: 1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: AppType.metaSm.copyWith(color: context.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _EmptySession extends StatelessWidget {
  const _EmptySession({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return LedgerPanel(
      grid: true,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('00', style: AppType.meta.copyWith(color: context.textTertiary)),
          const SizedBox(height: AppSpace.x2),
          Text(
            'Blank session',
            style: AppType.h2.copyWith(color: context.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'No exercises yet.\nAdd your first exercise to begin.',
            style: AppType.bodySm.copyWith(color: context.textSecondary),
          ),
          const SizedBox(height: AppSpace.x4),
          PushKey(
            key: const Key('add-exercise-empty'),
            label: 'Add Exercise',
            height: 48,
            onPressed: onAdd,
            icon: LedgerGlyph(
              LedgerGlyphType.plus,
              size: 15,
              strokeWidth: 2,
              color: onAccent(context.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExercisePanel extends StatelessWidget {
  const _ExercisePanel({
    super.key,
    required this.index,
    required this.exercise,
    required this.session,
    required this.unit,
    required this.onAddSet,
    required this.onEditSet,
    required this.onSupersetNext,
    required this.onRemove,
  });

  final int index;
  final Exercise exercise;
  final WorkoutSession session;
  final UnitSystem unit;
  final VoidCallback onAddSet;
  final void Function(WorkoutSet set, int number) onEditSet;
  final VoidCallback onSupersetNext;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final sets = session.setsFor(exercise.id);
    final group = session.supersetGroupOf(exercise.id);
    final isCardio = exercise.defaultMetric != 'weight_reps';
    final number = (index + 1).toString().padLeft(2, '0');

    return LedgerPanel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
            child: Row(
              children: [
                Text(
                  number,
                  style: AppType.meta.copyWith(color: context.textTertiary),
                ),
                const SizedBox(width: AppSpace.x3),
                Expanded(
                  child: Text(
                    exercise.name,
                    style: AppType.h2.copyWith(
                      color: context.textPrimary,
                      fontSize: 19,
                      height: 1.05,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (group != null)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: context.accent.withValues(alpha: 0.10),
                      border: Border.all(
                        color: context.accent.withValues(alpha: 0.35),
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.data),
                    ),
                    child: Text(
                      'SS$group',
                      style: AppType.metaSm.copyWith(color: context.accent),
                    ),
                  ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 19,
                    color: context.textTertiary,
                  ),
                  tooltip: 'Exercise options',
                  onSelected: (action) {
                    if (action == 'superset') onSupersetNext();
                    if (action == 'remove') onRemove();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'superset',
                      child: Text('Superset with next'),
                    ),
                    PopupMenuItem(
                      value: 'remove',
                      child: Text('Remove from workout'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Rule(),
          if (sets.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Text(
                'No sets yet — tap Add Set after your first effort.',
                style: AppType.bodySm.copyWith(color: context.textTertiary),
              ),
            )
          else
            for (var s = 0; s < sets.length; s++)
              _SetRow(
                number: s + 1,
                set: sets[s],
                isCardio: isCardio,
                unit: unit,
                onTap: () => onEditSet(sets[s], s + 1),
              ),
          Rule(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: OutlinedButton.icon(
              key: Key('add-set-${exercise.id}'),
              onPressed: onAddSet,
              style: _outlineStyle(context),
              icon: LedgerGlyph(
                LedgerGlyphType.plus,
                size: 13,
                color: context.textSecondary,
              ),
              label: const Text('Add Set'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.number,
    required this.set,
    required this.isCardio,
    required this.unit,
    required this.onTap,
  });

  final int number;
  final WorkoutSet set;
  final bool isCardio;
  final UnitSystem unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typeLabel = switch (set.setType) {
      'warmup' => 'WU',
      'drop' => 'DROP',
      'failure' => 'FAIL',
      _ => '',
    };

    final primary = isCardio
        ? '${set.distanceM?.round() ?? '—'} m'
        : '${set.weightKg != null ? formatWeight(set.weightKg!, unit) : '—'}'
              '${set.weightKg != null ? (unit == UnitSystem.kg ? ' kg' : ' lb') : ''}'
              ' × ${set.reps ?? '—'}';

    final secondary = isCardio
        ? set.durationSec != null
              ? '${(set.durationSec! / 60).toStringAsFixed(1)} min'
              : ''
        : set.rpe != null
        ? 'RPE ${set.rpe}'
        : '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: context.accent.withValues(alpha: 0.06),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: context.border)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '$number',
                  style: AppType.metaSm.copyWith(color: context.textTertiary),
                ),
              ),
              if (typeLabel.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    typeLabel,
                    style: AppType.metaSm.copyWith(
                      color: AppColors.heatWarm,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  primary,
                  style: AppType.data.copyWith(
                    color: context.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (secondary.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  secondary,
                  style: AppType.metaSm.copyWith(color: context.textSecondary),
                ),
              ],
              const SizedBox(width: 10),
              Icon(
                set.isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                size: 17,
                color: set.isCompleted ? context.accent : context.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

ButtonStyle _outlineStyle(BuildContext context) => OutlinedButton.styleFrom(
  foregroundColor: context.textPrimary,
  minimumSize: const Size.fromHeight(46),
  side: BorderSide(color: context.border),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.control),
  ),
  textStyle: AppType.button.copyWith(fontSize: 13, letterSpacing: 0.8),
);
