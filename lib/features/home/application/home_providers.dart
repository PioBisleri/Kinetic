import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../analytics/application/rollup_service.dart';
import '../../analytics/domain/analytics_math.dart';

/// One row of Home's "Recent workouts" list.
class RecentWorkout {
  const RecentWorkout({
    required this.workout,
    required this.title,
    required this.setCount,
    required this.exerciseCount,
  });

  final Workout workout;
  final String title; // routine name, or 'Workout' for empty sessions
  final int setCount; // completed sets only
  final int exerciseCount;
}

/// The 10 most recently finished workouts (newest first), enriched with
/// the routine title and per-workout set/exercise counts.
final recentWorkoutsProvider = StreamProvider<List<RecentWorkout>>((ref) {
  final db = ref.watch(databaseProvider);
  final q = db.workouts.select()
    ..where((w) => w.status.equals('completed'))
    ..orderBy([(w) => OrderingTerm.desc(w.startedAt)])
    ..limit(10);
  return q.watch().asyncMap((rows) async {
    if (rows.isEmpty) return const <RecentWorkout>[];

    final routineIds = <String>{
      for (final w in rows)
        if (w.routineId != null) w.routineId!,
    }.toList();
    final titles = <String, String>{};
    if (routineIds.isNotEmpty) {
      final routines =
          await (db.routines.select()..where((r) => r.id.isIn(routineIds)))
              .get();
      for (final r in routines) {
        if (r.deletedAt == null) titles[r.id] = r.name;
      }
    }

    final sets = await (db.workoutSets.select()
          ..where((s) =>
              s.workoutId.isIn([for (final w in rows) w.id]) &
              s.isCompleted.equals(true)))
        .get();
    final perWorkout = <String, List<WorkoutSet>>{};
    for (final s in sets) {
      perWorkout.putIfAbsent(s.workoutId, () => []).add(s);
    }

    return [
      for (final w in rows)
        RecentWorkout(
          workout: w,
          title: titles[w.routineId] ?? 'Workout',
          setCount: perWorkout[w.id]?.length ?? 0,
          exerciseCount: {
            for (final s in perWorkout[w.id] ?? const <WorkoutSet>[])
              s.exerciseId
          }.length,
        ),
    ];
  });
});

/// Hard-deletes one finished workout (and its sets), then rebuilds the
/// analytics rollups for every calendar day the workout touched, so
/// Analytics/Home/heat map all converge as if the workout never existed.
Future<void> deleteCompletedWorkout(AppDatabase db, String workoutId) async {
  final sets = await (db.workoutSets.select()
        ..where((s) => s.workoutId.equals(workoutId)))
      .get();
  final workout = await (db.workouts.select()
        ..where((w) => w.id.equals(workoutId)))
      .getSingleOrNull();
  if (workout == null) return;

  final days = <DateTime>{dayOf(workout.startedAt)};
  for (final s in sets) {
    if (s.isCompleted && s.loggedAt != null) days.add(dayOf(s.loggedAt!));
  }

  await db.transaction(() async {
    await (db.workoutSets.delete()
          ..where((s) => s.workoutId.equals(workoutId)))
        .go();
    await (db.workouts.delete()..where((w) => w.id.equals(workoutId))).go();
  });

  final rollups = RollupService(db);
  for (final d in days) {
    await rollups.recomputeDay(d);
  }
}
