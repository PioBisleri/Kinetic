import 'dart:convert';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/database.dart';
import '../../core/ledger/ledger.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_dialog.dart';
import '../analytics/widgets/charts.dart';
import 'widgets/exercise_progress_card.dart';

/// One exercise row, watched live.
final exerciseProvider = StreamProvider.autoDispose.family<Exercise?, String>(
  (ref, id) =>
      (ref.watch(databaseProvider).exercises.select()
            ..where((e) => e.id.equals(id)))
          .watchSingleOrNull(),
);

/// Weighted muscle contributors (primary 1.0 first), joined for names.
final exerciseMusclesProvider = StreamProvider.autoDispose
    .family<
      List<({String muscleId, String muscleName, double contribution})>,
      String
    >((ref, id) {
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
    });

/// How many logged sets reference this exercise (delete-dialog warning).
/// `readsFrom` keeps the stream live when sets are logged or deleted.
final exerciseUsageProvider = StreamProvider.autoDispose.family<int, String>((
  ref,
  id,
) {
  final db = ref.watch(databaseProvider);
  return db
      .customSelect(
        'SELECT COUNT(*) AS c FROM workout_sets '
        'WHERE exercise_id = ? AND deleted_at IS NULL',
        variables: [Variable.withString(id)],
        readsFrom: {db.workoutSets},
      )
      .map((row) => row.read<int>('c'))
      .watchSingle();
});

const _metricLabels = {
  'weight_reps': 'Weight × reps',
  'duration': 'Duration',
  'distance': 'Distance',
};

/// Full-screen detail: ledger spec, progress records and weighted muscle
/// contributors — edit for any exercise, delete for custom only.
class ExerciseDetailPage extends ConsumerWidget {
  const ExerciseDetailPage({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseAsync = ref.watch(exerciseProvider(exerciseId));
    final exercise = exerciseAsync.value;

    return Scaffold(
      appBar: TailBar(
        title: exercise?.name ?? 'Exercise',
        meta: exercise == null
            ? null
            : '${_titleCase(exercise.category)} · ${exercise.mechanics}',
        showMenu: false,
        actions: [
          if (exercise != null) ...[
            IconButton(
              key: const Key('edit-exercise'),
              tooltip: 'Edit exercise',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              icon: LedgerGlyph(
                LedgerGlyphType.edit,
                size: 19,
                color: context.textSecondary,
              ),
              onPressed: () => context.push('/library/$exerciseId/edit'),
            ),
            // Seeded exercises stay in the catalog — editable, not deletable.
            if (exercise.isCustom)
              IconButton(
                key: const Key('delete-exercise'),
                tooltip: 'Delete exercise',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                icon: LedgerGlyph(
                  LedgerGlyphType.trash,
                  size: 19,
                  color: context.danger,
                ),
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
          final equipment = (jsonDecode(e.equipment) as List).cast<String>();

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.x5,
              AppSpace.x2,
              AppSpace.x5,
              AppSpace.x8,
            ),
            children: [
              if (e.isCustom) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: _CustomBadge(),
                ),
                const SizedBox(height: AppSpace.x3),
              ],
              _DetailsGroup(exercise: e, equipment: equipment),
              if (e.defaultMetric == 'weight_reps') ...[
                const SizedBox(height: AppSpace.x5),
                ExerciseProgressCard(exerciseId: exerciseId),
              ],
              const SizedBox(height: AppSpace.x5),
              _MuscleContributionCard(muscles: muscles),
              if (usage > 0) ...[
                const SizedBox(height: AppSpace.x4),
                _UsageNote(usage: usage),
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

    final confirmed = await confirmAction(
      context,
      title: 'Delete ${exercise.name}?',
      message: usage > 0
          ? 'Logged in $usage ${usage == 1 ? 'workout' : 'workouts'} — '
                'past sets stay in your analytics, but the exercise '
                'leaves your library.'
          : 'It leaves your library. This can’t be undone.',
      confirmLabel: 'Delete',
      danger: true,
      confirmKey: const Key('confirm-delete'),
    );
    if (confirmed != true || !context.mounted) return;

    final db = ref.read(databaseProvider);
    await (db.update(
      db.exercises,
    )..where((e) => e.id.equals(exerciseId))).write(
      ExercisesCompanion(
        deletedAt: Value(DateTime.now().toUtc()),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
    if (context.mounted) context.pop();
  }
}

String _titleCase(String value) =>
    value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

class _CustomBadge extends StatelessWidget {
  const _CustomBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: context.accent.withValues(alpha: 0.65)),
        borderRadius: BorderRadius.circular(AppRadius.data),
      ),
      child: Text(
        'Custom exercise',
        style: AppType.metaSm.copyWith(
          color: context.accent,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _DetailsGroup extends StatelessWidget {
  const _DetailsGroup({required this.exercise, required this.equipment});

  final Exercise exercise;
  final List<String> equipment;

  @override
  Widget build(BuildContext context) {
    final metric =
        _metricLabels[exercise.defaultMetric] ?? exercise.defaultMetric;
    return LedgerGroup(
      index: '01',
      title: 'Details',
      meta: exercise.isCustom ? 'custom' : 'catalog',
      children: [
        LedgerRow(label: 'Category', value: _titleCase(exercise.category)),
        LedgerRow(label: 'Type', value: exercise.mechanics),
        LedgerRow(label: 'Force', value: exercise.forceType ?? '—'),
        LedgerRow(label: 'Logging', value: metric),
        if (equipment.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EQUIPMENT',
                  style: AppType.metaSm.copyWith(color: context.textTertiary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final item in equipment) _EquipmentTag(item: item),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _EquipmentTag extends StatelessWidget {
  const _EquipmentTag({required this.item});

  final String item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: context.border),
        borderRadius: BorderRadius.circular(AppRadius.data),
      ),
      child: Text(
        item,
        style: AppType.metaSm.copyWith(
          color: context.textSecondary,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _MuscleContributionCard extends StatelessWidget {
  const _MuscleContributionCard({required this.muscles});

  final AsyncValue<
    List<({String muscleId, String muscleName, double contribution})>
  >
  muscles;

  @override
  Widget build(BuildContext context) {
    return ChartCard(
      index: '03',
      title: 'Muscle contributions',
      subtitle: 'weighted share of training stress',
      child: muscles.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(8),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (e, _) => Text('Error: $e'),
        data: (rows) => Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpace.x3),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      rows[i].muscleName,
                      style: AppType.bodySm.copyWith(
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${(rows[i].contribution * 100).round()}%',
                    style: AppType.dataSm.copyWith(
                      color: context.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ProgressRule(
                key: Key('contribution-${rows[i].muscleId}'),
                value: rows[i].contribution.clamp(0.0, 1.0).toDouble(),
                segments: 20,
                height: 6,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UsageNote extends StatelessWidget {
  const _UsageNote({required this.usage});

  final int usage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 5, height: 5, color: context.accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Logged in $usage ${usage == 1 ? 'workout' : 'workouts'}',
            style: AppType.metaSm.copyWith(color: context.textTertiary),
          ),
        ),
      ],
    );
  }
}
