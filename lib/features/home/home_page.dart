import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/weight_units.dart';
import '../workout/application/workout_session_notifier.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    await ref.read(workoutSessionProvider.notifier).startWorkout();
    if (context.mounted) context.push('/workout');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(workoutSessionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kinetic')),
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
                ? _StartWorkoutCard(onStart: () => _start(context, ref))
                : _ActiveWorkoutCard(
                    session: session,
                    onResume: () => context.push('/workout'),
                  ),
          ),
          const SizedBox(height: 16),
          const _StatRow(
            stats: [
              ('This week', '3', 'workouts'),
              ('Volume', '24.1k', 'kg'),
              ('Streak', '5', 'days'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Recent workouts',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Card(
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
          ),
        ],
      ),
    );
  }
}

class _StartWorkoutCard extends StatelessWidget {
  const _StartWorkoutCard({required this.onStart});

  final VoidCallback onStart;

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
