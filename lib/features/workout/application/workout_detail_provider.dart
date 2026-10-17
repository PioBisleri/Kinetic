import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../analytics/domain/analytics_math.dart';

/// One exercise's block in the workout history detail page: the exercise's
/// name plus every set row, in the order the session logged them.
class WorkoutSetGroup {
  const WorkoutSetGroup({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
  });

  final String exerciseId;
  final String exerciseName;
  final List<WorkoutSet> sets;
}

/// Everything `/workout-history/:id` renders: the workout row, its routine
/// title and its sets grouped per exercise (first appearance keeps the
/// block together — supersets and interleaved moves stay in logged order).
class WorkoutDetail {
  const WorkoutDetail({
    required this.workout,
    required this.title,
    required this.groups,
    required this.setCount,
    required this.volumeKg,
  });

  final Workout workout;
  final String title; // routine name, or 'Workout' for ad-hoc sessions
  final List<WorkoutSetGroup> groups;
  final int setCount; // completed sets, same semantics as Home's tile
  final double volumeKg; // completed hard sets only (matches the rollup)
}

/// Loads one finished workout with exercise names resolved. A missing
/// workout (e.g. deleted between taps) yields null and the page says so.
final workoutDetailProvider =
    FutureProvider.family<WorkoutDetail?, String>((ref, workoutId) async {
  final db = ref.watch(databaseProvider);

  final workout = await (db.workouts.select()
        ..where((w) => w.id.equals(workoutId)))
      .getSingleOrNull();
  if (workout == null) return null;

  final sets = await db.setsForWorkout(workoutId);

  final routineIds = <String, String>{};
  if (workout.routineId != null) {
    final routine = await (db.routines.select()
          ..where((r) => r.id.equals(workout.routineId!)))
        .getSingleOrNull();
    if (routine != null && routine.deletedAt == null) {
      routineIds[routine.id] = routine.name;
    }
  }

  final names = <String, String>{};
  final exerciseIds = <String>{for (final s in sets) s.exerciseId};
  if (exerciseIds.isNotEmpty) {
    final exercises = await (db.exercises.select()
          ..where((e) => e.id.isIn(exerciseIds.toList())))
        .get();
    for (final e in exercises) {
      names[e.id] = e.name;
    }
  }

  final groups = <WorkoutSetGroup>[];
  final index = <String, WorkoutSetGroup>{};
  for (final s in sets) {
    final g = index[s.exerciseId];
    if (g == null) {
      final created = WorkoutSetGroup(
        exerciseId: s.exerciseId,
        exerciseName: names[s.exerciseId] ?? 'Custom exercise',
        sets: [s],
      );
      index[s.exerciseId] = created;
      groups.add(created);
    } else {
      g.sets.add(s);
    }
  }

  var setCount = 0;
  var volumeKg = 0.0;
  for (final s in sets) {
    if (!s.isCompleted) continue;
    setCount++;
    if (hardSetTypes.contains(s.setType)) {
      volumeKg += (s.weightKg ?? 0) * (s.reps ?? 0);
    }
  }

  return WorkoutDetail(
    workout: workout,
    title: routineIds[workout.routineId] ?? 'Workout',
    groups: groups,
    setCount: setCount,
    volumeKg: volumeKg,
  );
});
