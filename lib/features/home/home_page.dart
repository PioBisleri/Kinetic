import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';
import '../../core/navigation/shell_navigation.dart';
import '../../core/settings/settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/weight_units.dart';
import '../analytics/application/analytics_providers.dart';
import '../analytics/domain/analytics_math.dart';
import '../routines/application/routine_providers.dart';
import '../workout/application/workout_session_notifier.dart';
import 'application/home_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    await ref.read(workoutSessionProvider.notifier).startWorkout();
    if (context.mounted) context.push('/workout');
  }

  Future<void> _startRoutine(
      BuildContext context, WidgetRef ref, String routineId) async {
    final session = ref.read(workoutSessionProvider).value;
    if (session != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Finish your current workout first.')),
      );
      return;
    }
    await ref
        .read(workoutSessionProvider.notifier)
        .startWorkout(routineId: routineId);
    if (context.mounted) context.push('/workout');
  }

  void _openRoutinePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
      ),
      builder: (_) => Consumer(
        builder: (sheetContext, ref, _) {
          final cards = ref.watch(routinesProvider);
          final routines = cards.value ?? const <RoutineCard>[];
          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    'Start from routine',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                for (final card in routines)
                  ListTile(
                    key: Key('home-routine-${card.routine.id}'),
                    title: Text(card.routine.name),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _startRoutine(context, ref, card.routine.id);
                    },
                  ),
                if (routines.isEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Text(
                      'No routines yet — create one from the Routines tab.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(workoutSessionProvider);
    final unit = ref.watch(settingsProvider).unit;

    return Scaffold(
      appBar: AppBar(
        leading: const DrawerMenuButton(),
        title: const Text('Kinetic'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          sessionAsync.when(
            loading: () => const Card(
              child: SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Error: $e'),
              ),
            ),
            data: (session) => session == null
                ? _StartWorkoutCard(
                    onStart: () => _start(context, ref),
                    onStartRoutine: () => _openRoutinePicker(context, ref),
                  )
                : _ActiveWorkoutCard(
                    session: session,
                    onResume: () => context.push('/workout'),
                  ),
          ),
          const SizedBox(height: 16),
          _HomeStats(unit: unit),
          const SizedBox(height: 16),
          Text(
            'Recent workouts',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          const _RecentWorkouts(),
        ],
      ),
    );
  }
}

class _StartWorkoutCard extends StatelessWidget {
  const _StartWorkoutCard({
    required this.onStart,
    required this.onStartRoutine,
  });

  final VoidCallback onStart;
  final VoidCallback onStartRoutine;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ready to train?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Start an empty session or pick a routine.',
              style: TextStyle(color: context.textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start Workout'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onStartRoutine,
              icon: const Icon(Icons.list_alt),
              label: const Text('Start from routine…'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveWorkoutCard extends StatelessWidget {
  const _ActiveWorkoutCard({required this.session, required this.onResume});

  final WorkoutSession session;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.heatHot,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'WORKOUT IN PROGRESS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: context.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  formatElapsed(session.elapsed),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${session.exercises.length} exercises · '
              '${session.completedSetCount} sets · '
              '${session.volumeKg.toStringAsFixed(0)} kg volume',
              style: TextStyle(color: context.textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onResume,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Resume Workout'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.stats});

  final List<(String, String, String)> stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (label, value, unit) in stats) ...[
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 12, color: context.textSecondary)),
                    const SizedBox(height: 6),
                    Text.rich(
                      TextSpan(
                        text: value,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5),
                        children: [
                          TextSpan(
                            text: ' $unit',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: context.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (label != stats.last.$1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

/// The three headline stats, computed from real history: workouts finished
/// this week (Mon-start), total working volume this week, and the weekly
/// streak. Mirrors Analytics' `StatsRow` numbers exactly (same providers).
class _HomeStats extends ConsumerWidget {
  const _HomeStats({required this.unit});

  final UnitSystem unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(workoutStatsProvider(1)).value;
    final daily = ref.watch(dailyVolumeProvider(1)).value;

    if (stats == null || daily == null) {
      return const _StatRow(stats: [
        ('This week', '–', 'workouts'),
        ('Volume', '–', ''),
        ('Streak', '–', 'weeks'),
      ]);
    }

    final volumeKg = daily.fold(0.0, (a, r) => a + r.totalVolume);
    return _StatRow(stats: [
      (
        'This week',
        '${stats.count}',
        stats.count == 1 ? 'workout' : 'workouts',
      ),
      (
        'Volume',
        compactNumber(kgToDisplay(volumeKg, unit)),
        unitLabel(unit),
      ),
      (
        'Streak',
        '${stats.streak}',
        stats.streak == 1 ? 'week' : 'weeks',
      ),
    ]);
  }
}

/// Finished workouts, newest first. Long-press a row to delete it (with
/// confirmation); analytics rollups recompute so every chart agrees.
class _RecentWorkouts extends ConsumerWidget {
  const _RecentWorkouts();

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, RecentWorkout row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete workout?'),
        content: Text(
          '${row.title} · '
          '${DateFormat('EEE, MMM d').format(row.workout.startedAt)}\n\n'
          'This removes the workout and its sets from your history. '
          'Charts and totals recompute immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.heatHot,
              minimumSize: const Size(0, 44),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await deleteCompletedWorkout(ref.read(databaseProvider), row.workout.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentWorkoutsProvider);
    final unit = ref.watch(settingsProvider).unit;

    return recent.when(
      loading: () => const Card(
        child: SizedBox(
          height: 72,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Error: $e'),
        ),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No workouts yet — your history will appear here.',
                  style: TextStyle(color: context.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        return Column(
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    _RecentTile(
                      row: rows[i],
                      unit: unit,
                      onDelete: () => _confirmDelete(context, ref, rows[i]),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Long-press a workout to delete it',
              style: TextStyle(fontSize: 11.5, color: context.textSecondary),
            ),
          ],
        );
      },
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({
    required this.row,
    required this.unit,
    required this.onDelete,
  });

  final RecentWorkout row;
  final UnitSystem unit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final w = row.workout;
    final minutes = (w.durationSec ?? 0) ~/ 60;
    final duration =
        minutes >= 60 ? '${minutes ~/ 60}h ${minutes % 60}m' : '${minutes}m';

    return ListTile(
      dense: true,
      title: Text(
        row.title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
      ),
      subtitle: Text(
        '${DateFormat('EEE, MMM d').format(w.startedAt)} · '
        '$duration · ${row.setCount} sets',
        style: TextStyle(fontSize: 12.5, color: context.textSecondary),
      ),
      trailing: Text(
        '${compactNumber(kgToDisplay(w.totalVolume, unit))} '
        '${unitLabel(unit)}',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      onLongPress: onDelete,
    );
  }
}
