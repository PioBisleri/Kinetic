import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';

/// Family over category so sheets/pages can watch filtered catalog
/// queries reactively. Search runs client-side over these rows — see
/// core/search/smart_search.dart.
final dbExercisesProvider = StreamProvider.autoDispose
    .family<List<Exercise>, ({String? category})>(
  (ref, args) => ref.watch(databaseProvider).watchExercises(
        category: args.category,
      ),
);

final dbExerciseCountProvider = StreamProvider.autoDispose<int>(
  (ref) => ref.watch(databaseProvider).exerciseCount(),
);

final dbActiveWorkoutProvider = StreamProvider.autoDispose<Workout?>(
  (ref) => ref.watch(databaseProvider).watchActiveWorkout(),
);

/// The local (pre-auth) profile row — carries bodyweight for the Muscle
/// Grade strength component.
final profileProvider = StreamProvider<Profile?>(
  (ref) => (ref.watch(databaseProvider).profiles.select()
        ..where((p) => p.id.equals('local')))
      .watch()
      .map((rows) => rows.isEmpty ? null : rows.first),
);

/// Weight-trend points (Round 6): one row per local day, oldest first,
/// tombstones excluded.
final bodyMetricsProvider = StreamProvider<List<BodyMetric>>((ref) {
  final q = ref.watch(databaseProvider).bodyMetrics.select()
    ..where((m) => m.deletedAt.isNull())
    ..orderBy([(m) => OrderingTerm.asc(m.id)]);
  return q.watch();
});

/// Muscle catalog in display order (grade board + heat map).
final musclesProvider = StreamProvider<List<MuscleGroup>>((ref) {
  final db = ref.watch(databaseProvider);
  final q = db.muscleGroups.select()
    ..orderBy([(m) => OrderingTerm.asc(m.orderIndex)]);
  return q.watch();
});

/// Muscle id → display name for search ranking. Empty until the muscle
/// stream emits; searchCatalog then falls back to the spaced id.
final muscleNamesProvider = Provider<Map<String, String>>((ref) {
  final async = ref.watch(musclesProvider);
  return switch (async) {
    AsyncData(:final value) => {for (final m in value) m.id: m.name},
    _ => const <String, String>{},
  };
});

/// The view-only weekly plan rows (weekday 1..7). Tombstones excluded;
/// a row with a null routineId simply renders as a rest day.
final weeklyPlanProvider = StreamProvider<List<WeeklyPlan>>((ref) {
  final db = ref.watch(databaseProvider);
  final q = db.weeklyPlans.select()
    ..where((w) => w.deletedAt.isNull())
    ..orderBy([(w) => OrderingTerm.asc(w.weekday)]);
  return q.watch();
});
