import 'package:drift/drift.dart';

import '../../features/analytics/application/rollup_service.dart';
import '../../features/analytics/domain/analytics_math.dart';
import 'database.dart';
import 'seed_service.dart';

/// Hard deletions for Profile → Data.
///
/// Sync isn't live yet (Phase 10), so rows are removed outright — no
/// tombstones — and every affected calendar day's rollups are rebuilt
/// afterwards, so Home/Analytics/heat map converge immediately.
class DeleteService {
  DeleteService(this._db);

  final AppDatabase _db;

  /// Everything the user owns: history, routines, custom exercises and
  /// the profile row. The muscle-group catalog is bundled content and
  /// stays; the exercise catalog is re-seeded from the assets.
  Future<void> deleteAllData() async {
    await _db.transaction(() async {
      await _db.delete(_db.workoutSets).go();
      await _db.delete(_db.workouts).go();
      await _db.delete(_db.routineExercises).go();
      await _db.delete(_db.routines).go();
      await _db.delete(_db.exerciseHistory).go();
      await _db.delete(_db.muscleVolumeDaily).go();
      await _db.delete(_db.muscleGradeHistory).go();
      await _db.delete(_db.bodyMetrics).go();
      await _db.delete(_db.volumeLandmarks).go();
      await _db.delete(_db.exerciseMuscleMap).go();
      await _db.delete(_db.exercises).go();
      await _db.delete(_db.profiles).go();
    });
    await SeedService(_db).ensureSeeded();
  }

  /// Finished workout history only — an in-progress session (its workout
  /// row and sets) is left alone, and days that still hold active-session
  /// sets are rebuilt from what remains.
  Future<void> deleteWorkoutHistory() async {
    final all = await _db.workouts.select().get();
    final finished = [for (final w in all) if (w.status != 'active') w];
    if (finished.isEmpty) return;
    final ids = [for (final w in finished) w.id];

    final removedSets = await (_db.workoutSets.select()
          ..where((s) => s.workoutId.isIn(ids)))
        .get();
    final days = <DateTime>{
      for (final s in removedSets)
        if (s.isCompleted && s.loggedAt != null) dayOf(s.loggedAt!),
    };

    await _db.transaction(() async {
      await (_db.workoutSets.delete()..where((s) => s.workoutId.isIn(ids)))
          .go();
      await (_db.workouts.delete()..where((w) => w.id.isIn(ids))).go();
      await _db.delete(_db.muscleGradeHistory).go();
    });

    final rollups = RollupService(_db);
    for (final day in days) {
      await rollups.recomputeDay(day);
    }
  }

  /// Every routine and its slots. Workout history keeps its rows (a live
  /// session that started from a routine just falls back to no title).
  Future<void> deleteRoutines() async {
    await _db.transaction(() async {
      await _db.delete(_db.routineExercises).go();
      await _db.delete(_db.routines).go();
    });
  }

  /// User-created exercises plus everything that referenced them: their
  /// logged sets, routine slots, muscle-map rows and history. Then the
  /// affected days' rollups and each touched workout's total are repaired.
  Future<void> deleteCustomExercises() async {
    final custom = await (_db.exercises.select()
          ..where((e) => e.isCustom & e.deletedAt.isNull()))
        .get();
    if (custom.isEmpty) return;
    final ids = [for (final e in custom) e.id];

    final sets = await (_db.workoutSets.select()
          ..where((s) => s.exerciseId.isIn(ids)))
        .get();
    final days = <DateTime>{};
    final touchedWorkouts = <String>{};
    for (final s in sets) {
      touchedWorkouts.add(s.workoutId);
      if (s.isCompleted && s.loggedAt != null) days.add(dayOf(s.loggedAt!));
    }

    await _db.transaction(() async {
      await (_db.workoutSets.delete()..where((s) => s.exerciseId.isIn(ids)))
          .go();
      await (_db.exerciseHistory.delete()..where((h) => h.exerciseId.isIn(ids)))
          .go();
      await (_db.exerciseMuscleMap.delete()
            ..where((m) => m.exerciseId.isIn(ids)))
          .go();
      await (_db.routineExercises.delete()..where((r) => r.exerciseId.isIn(ids)))
          .go();
      await (_db.exercises.delete()..where((e) => e.id.isIn(ids))).go();
    });

    final rollups = RollupService(_db);
    for (final day in days) {
      await rollups.recomputeDay(day);
    }
    for (final workoutId in touchedWorkouts) {
      await _recomputeWorkoutTotal(workoutId);
    }
  }

  /// Recomputes `total_volume` from a workout's remaining completed sets
  /// (its sets may have just disappeared together with their exercise).
  Future<void> _recomputeWorkoutTotal(String workoutId) async {
    final sets = await (_db.workoutSets.select()
          ..where((s) => s.workoutId.equals(workoutId)))
        .get();
    final total = sets
        .where((s) => s.isCompleted && hardSetTypes.contains(s.setType))
        .fold(0.0, (a, s) => a + (s.weightKg ?? 0) * (s.reps ?? 0));
    await (_db.workouts.update()..where((w) => w.id.equals(workoutId))).write(
      WorkoutsCompanion(
        totalVolume: Value(total),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
