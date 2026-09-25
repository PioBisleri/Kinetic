import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../workout/application/workout_session_notifier.dart';
import 'application/routine_providers.dart';

/// The Routines tab: saved plans, one-tap start, and entry points to the
/// builder and the exercise library.
class RoutinesPage extends ConsumerWidget {
  const RoutinesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routines = ref.watch(routinesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Routines'),
        actions: [
          IconButton(
            key: const Key('open-library'),
            tooltip: 'Exercise Library',
            icon: const Icon(Icons.fitness_center_outlined),
            onPressed: () => context.push('/library'),
          ),
        ],
      ),
      body: routines.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (cards) => cards.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.playlist_add_check_circle_rounded,
                        size: 48, color: context.textTertiary),
                    const SizedBox(height: 12),
                    const Text('No routines yet'),
                    const SizedBox(height: 4),
                    Text(
                      'Build a reusable plan, then start it in one tap.',
                      style:
                          TextStyle(color: context.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                itemCount: cards.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final card = cards[i];
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      title: Text(
                        card.routine.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${card.exerciseCount} exercises · '
                        '${card.targetSetCount} sets',
                        style: TextStyle(
                            fontSize: 12, color: context.textSecondary),
                      ),
                      trailing: IconButton(
                        key: Key('start-routine-${card.routine.id}'),
                        tooltip: 'Start workout',
                        iconSize: 30,
                        icon: const Icon(Icons.play_circle_fill_rounded,
                            color: AppColors.accent),
                        onPressed: () =>
                            _startRoutine(context, ref, card.routine.id),
                      ),
                      onTap: () => context.push('/routines/${card.routine.id}'),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('new-routine'),
        tooltip: 'New Routine',
        onPressed: () => context.push('/routines/new'),
        child: const Icon(Icons.add),
      ),
    );
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
}
