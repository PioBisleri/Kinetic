import 'dart:convert';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/database.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/exercise_animation.dart';

/// One exercise row, watched live.
final exerciseProvider = StreamProvider.autoDispose.family<Exercise?, String>(
  (ref, id) => (ref.watch(databaseProvider).exercises.select()
        ..where((e) => e.id.equals(id)))
      .watchSingleOrNull(),
);

/// Weighted muscle contributors (primary 1.0 first), joined for names.
final exerciseMusclesProvider = StreamProvider.autoDispose
    .family<List<({String muscleId, String muscleName, double contribution})>,
        String>(
  (ref, id) {
    final db = ref.watch(databaseProvider);
    final query = db.selectOnly(db.exerciseMuscleMap)
      ..addColumns([
        db.muscleGroups.id,
        db.muscleGroups.name,
        db.exerciseMuscleMap.contribution,
      ])
      ..where(db.exerciseMuscleMap.exerciseId.equals(id))
      ..orderBy([OrderingTerm.desc(db.exerciseMuscleMap.contribution)])
      ..join([
        innerJoin(
          db.muscleGroups,
          db.muscleGroups.id.equalsExp(db.exerciseMuscleMap.muscleId),
        ),
      ]);
    return query.watch().map(
          (rows) => rows
              .map(
                (r) => (
                  muscleId: r.read(db.muscleGroups.id)!,
                  muscleName: r.read(db.muscleGroups.name)!,
                  contribution: r.read(db.exerciseMuscleMap.contribution)!,
                ),
              )
              .toList(),
        );
  },
);

/// How many logged sets reference this exercise (delete-dialog warning).
final exerciseUsageProvider = StreamProvider.autoDispose.family<int, String>(
  (ref, id) => ref.watch(databaseProvider).customSelect(
        'SELECT COUNT(*) AS c FROM workout_sets '
        'WHERE exercise_id = ? AND deleted_at IS NULL',
        variables: [Variable.withString(id)],
      ).map((row) => row.read<int>('c')).watchSingle(),
);

const _metricLabels = {
  'weight_reps': 'Weight × reps',
  'duration': 'Duration',
  'distance': 'Distance',
};

/// Full-screen detail: animation hero, metadata, weighted muscle
/// contributors — plus edit/delete for custom exercises.
class ExerciseDetailPage extends ConsumerWidget {
  const ExerciseDetailPage({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseAsync = ref.watch(exerciseProvider(exerciseId));
    final exercise = exerciseAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          exercise?.name ?? 'Exercise',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (exercise != null && exercise.isCustom) ...[
            IconButton(
              key: const Key('edit-exercise'),
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit exercise',
              onPressed: () => context.push('/library/$exerciseId/edit'),
            ),
            IconButton(
              key: const Key('delete-exercise'),
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete exercise',
              onPressed: () => _confirmDelete(context, ref, exercise),
            ),
          ],
        ],
      ),
      body: exerciseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (e) {
          if (e == null) {
            return const Center(child: Text('Exercise not found'));
          }
          final muscles = ref.watch(exerciseMusclesProvider(exerciseId));
          final usage = ref.watch(exerciseUsageProvider(exerciseId)).value ?? 0;
          final equipment =
              (jsonDecode(e.equipment) as List).cast<String>();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              if (e.isCustom)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _CustomBadge(),
                  ),
                ),
              Card(
                clipBehavior: Clip.antiAlias,
                child: ExerciseAnimation(
                  animationKind: e.animationKind,
                  animationRef: e.animationRef,
                ),
              ),
              const SizedBox(height: 16),
              _DetailsCard(exercise: e, equipment: equipment),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Muscle contributions',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      muscles.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(8),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        error: (e, _) => Text('Error: $e'),
                        data: (rows) => Column(
                          children: [
                            for (final row in rows)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            row.muscleName,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: context.textPrimary,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${(row.contribution * 100).round()}%',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.accent,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(3),
                                      child: LinearProgressIndicator(
                                        key: Key(
                                            'contribution-${row.muscleId}'),
                                        value: row.contribution
                                            .clamp(0.0, 1.0)
                                            .toDouble(),
                                        minHeight: 6,
                                        color: AppColors.accent,
                                        backgroundColor:
                                            context.surfaceElevated,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (usage > 0) ...[
                const SizedBox(height: 16),
                Text(
                  'Logged in $usage ${usage == 1 ? 'workout' : 'workouts'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Exercise exercise,
  ) async {
    final usage = await ref.read(exerciseUsageProvider(exerciseId).future);
    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${exercise.name}?'),
        content: Text(
          usage > 0
              ? 'Logged in $usage ${usage == 1 ? 'workout' : 'workouts'} — '
                  'past sets stay in your analytics, but the exercise '
                  'leaves your library.'
              : 'It leaves your library. This can’t be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('confirm-delete'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final db = ref.read(databaseProvider);
    await (db.update(db.exercises)..where((e) => e.id.equals(exerciseId)))
        .write(ExercisesCompanion(
      deletedAt: Value(DateTime.now().toUtc()),
      updatedAt: Value(DateTime.now().toUtc()),
    ));
    if (context.mounted) context.pop();
  }
}

class _CustomBadge extends StatelessWidget {
  const _CustomBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
      ),
      child: const Text(
        'Custom exercise',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.accent,
        ),
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.exercise, required this.equipment});

  final Exercise exercise;
  final List<String> equipment;

  @override
  Widget build(BuildContext context) {
    final category = exercise.category.isEmpty
        ? exercise.category
        : exercise.category[0].toUpperCase() + exercise.category.substring(1);

    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 92,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            row('Category', category),
            row('Type', exercise.mechanics),
            row('Force', exercise.forceType ?? '—'),
            row(
              'Logging',
              _metricLabels[exercise.defaultMetric] ?? exercise.defaultMetric,
            ),
            if (equipment.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final item in equipment)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: context.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: context.border),
                      ),
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
