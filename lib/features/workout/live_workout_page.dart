import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/database.dart';
import '../../core/settings/settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/weight_units.dart';
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

  /// Rest periods by set type (seconds).
  static const _restByType = {
    'working': 90,
    'drop': 90,
    'failure': 120,
    'warmup': 60,
  };

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
        const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _finish(WorkoutSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finish workout?'),
        content: Text(
          '${session.exercises.length} exercises · '
          '${session.completedSetCount} sets · '
          '${formatElapsed(session.elapsed)}\n'
          'Volume: ${session.volumeKg.toStringAsFixed(0)} kg',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep going'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            child: const Text('Finish'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(workoutSessionProvider.notifier).finishWorkout();
    if (mounted) context.pop();
  }

  Future<void> _editNotes(WorkoutSession session) async {
    final controller = TextEditingController(
        text: session.workout.notes ?? '');
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Workout notes',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800)),
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
                onPressed: () =>
                    Navigator.of(context).pop(controller.text),
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
    await notifier.logSet(
      exerciseId: exercise.id,
      setType: result.setType,
      weightKg: result.weightKg,
      reps: result.reps,
      rpe: result.rpe,
      distanceM: result.distanceM,
      durationSec: result.durationSec,
      heartRate: result.heartRate,
    );

    final rest = _restByType[result.setType];
    if (rest != null && mounted) {
      ref.read(restTimerProvider.notifier).start(rest);
    }
  }

  Future<void> _editSet(
      Exercise exercise, WorkoutSet set, int number) async {
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
        final rest = _restByType[result.setType];
        if (rest != null) ref.read(restTimerProvider.notifier).start(rest);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(workoutSessionProvider);
    final unit = ref.watch(settingsProvider).unit;

    return Scaffold(
      appBar: AppBar(
        title: sessionAsync.when(
          data: (s) =>
              Text(s == null ? 'Workout' : formatElapsed(s.elapsed)),
          loading: () => const Text('Workout'),
          error: (_, _) => const Text('Workout'),
        ),
        actions: [
          IconButton(
            tooltip: 'Notes',
            icon: const Icon(Icons.notes_rounded),
            onPressed: sessionAsync.value == null
                ? null
                : () => _editNotes(sessionAsync.value!),
          ),
          TextButton(
            onPressed: sessionAsync.value == null
                ? null
                : () => _finish(sessionAsync.value!),
            child: const Text('Finish',
                style: TextStyle(fontWeight: FontWeight.w700)),
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fitness_center_rounded,
                        size: 48, color: context.textTertiary),
                    const SizedBox(height: 12),
                    Text(
                      'No exercises yet.\nAdd your first exercise to begin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      key: const Key('add-exercise-empty'),
                      onPressed: _addExercise,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Exercise'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              for (var i = 0; i < session.exercises.length; i++)
                _ExerciseCard(
                  key: ValueKey(session.exercises[i].id),
                  exercise: session.exercises[i],
                  session: session,
                  unit: unit,
                  onAddSet: () => _logSet(session.exercises[i], session),
                  onEditSet: (set, number) =>
                      _editSet(session.exercises[i], set, number),
                  onSupersetNext: () => ref
                      .read(workoutSessionProvider.notifier)
                      .supersetWithNext(session.exercises[i].id),
                  onRemove: () => ref
                      .read(workoutSessionProvider.notifier)
                      .removeExercise(session.exercises[i].id),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const Key('add-exercise'),
                onPressed: _addExercise,
                icon: const Icon(Icons.add),
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

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    super.key,
    required this.exercise,
    required this.session,
    required this.unit,
    required this.onAddSet,
    required this.onEditSet,
    required this.onSupersetNext,
    required this.onRemove,
  });

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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    exercise.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                if (group != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'SS$group',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent),
                    ),
                  ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (action) {
                    if (action == 'superset') onSupersetNext();
                    if (action == 'remove') onRemove();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'superset',
                      child: Text('Superset with next'),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Text('Remove from workout'),
                    ),
                  ],
                ),
              ],
            ),
            if (sets.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No sets yet — tap Add Set after your first effort.',
                  style: TextStyle(
                      fontSize: 13, color: context.textTertiary),
                ),
              )
            else
              for (var s = 0; s < sets.length; s++) _SetRow(
                    number: s + 1,
                    set: sets[s],
                    isCardio: isCardio,
                    unit: unit,
                    onTap: () => onEditSet(sets[s], s + 1),
                  ),
            const SizedBox(height: 4),
            FilledButton.tonal(
              key: Key('add-set-${exercise.id}'),
              onPressed: onAddSet,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: context.surfaceElevated,
                foregroundColor: context.textPrimary,
              ),
              child: const Text('Add Set'),
            ),
          ],
        ),
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
        : set.rpe != null ? 'RPE ${set.rpe}' : '';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: context.background.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text('$number',
                  style: TextStyle(
                      color: context.textTertiary,
                      fontWeight: FontWeight.w700)),
            ),
            if (typeLabel.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  typeLabel,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.heatWarm),
                ),
              ),
            Expanded(
              child: Text(
                primary,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()]),
              ),
            ),
            if (secondary.isNotEmpty)
              Text(secondary,
                  style: TextStyle(
                      fontSize: 13, color: context.textSecondary)),
            const SizedBox(width: 8),
            // Planned (routine) sets show hollow until completed.
            Icon(
              set.isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              size: 18,
              color:
                  set.isCompleted ? AppColors.accent : context.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
