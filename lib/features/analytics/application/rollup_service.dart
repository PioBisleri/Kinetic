import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../../../core/database/database.dart';
import '../domain/analytics_math.dart';
import '../domain/grade_engine.dart';

/// Maintains the analytics rollup tables (`ExerciseHistory`,
/// `MuscleVolumeDaily`) from the raw `workout_sets` rows.
///
/// Strategy: recompute whole calendar days on every mutation instead of
/// applying deltas — log/edit/delete then all converge to the same result
/// and the operation is idempotent (safe to re-run, safe to overlap with
/// the boot backfill).
class RollupService {
  RollupService(this._db);

  final AppDatabase _db;

  /// Local-only user until Phase 7 introduces auth.
  static const _userId = 'local';

  /// Rebuild both rollup tables for the calendar day containing [day].
  Future<void> recomputeDay(DateTime day) async {
    final start = dayOf(day);
    final end = addDays(start, 1);

    // Completed sets are always stamped with loggedAt, so the day bucket is
    // simply the loggedAt range.
    final sets = await (_db.workoutSets.select()
          ..where((s) =>
              s.isCompleted.equals(true) &
              s.loggedAt.isBiggerOrEqualValue(start) &
              s.loggedAt.isSmallerThanValue(end)))
        .get();

    final byExercise = <String, List<WorkoutSet>>{};
    for (final s in sets) {
      if (!hardSetTypes.contains(s.setType)) continue;
      byExercise.putIfAbsent(s.exerciseId, () => []).add(s);
    }

    await _db.transaction(() async {
      // Wipe-and-rebuild the day (a day is a handful of rows).
      await (_db.exerciseHistory.delete()
            ..where((h) =>
                h.userId.equals(_userId) & h.date.equals(start)))
          .go();
      await (_db.muscleVolumeDaily.delete()
            ..where((m) =>
                m.userId.equals(_userId) & m.date.equals(start)))
          .go();
      if (byExercise.isEmpty) return;

      // --- per-exercise stats ------------------------------------------
      final stats = <String, _ExDayStats>{};
      for (final entry in byExercise.entries) {
        final st = _ExDayStats(setCount: entry.value.length);
        for (final s in entry.value) {
          final w = s.weightKg;
          final reps = s.reps;
          if (w == null || reps == null) continue;
          st.volume += w * reps;
          // Epley is only meaningful for reps ≤ 10 (see GradeEngine).
          if (w > 0 && reps > 0 && reps <= 10) {
            st.bestE1Rm = math.max(st.bestE1Rm, GradeEngine.epley1Rm(w, reps));
          }
          if (w > st.topWeight) {
            st.topWeight = w;
            st.topReps = reps;
          }
        }
        stats[entry.key] = st;
      }

      // History rows only for exercises with something to chart — a
      // duration-only set (plank, cardio) still credits muscle sets below.
      for (final e in stats.entries) {
        final st = e.value;
        if (st.volume <= 0 && st.bestE1Rm <= 0) continue;
        await _db.exerciseHistory.insertOnConflictUpdate(
          ExerciseHistoryCompanion.insert(
            userId: _userId,
            exerciseId: e.key,
            date: start,
            bestE1Rm: Value(st.bestE1Rm),
            topWeight: Value(st.topWeight),
            topReps: Value(st.topReps),
            totalVolume: Value(st.volume),
          ),
        );
      }

      // --- per-muscle attribution --------------------------------------
      final maps = await (_db.exerciseMuscleMap.select()
            ..where((m) => m.exerciseId.isIn(byExercise.keys.toList())))
          .get();

      final perMuscle = <String, _MuscleDayStats>{};
      for (final m in maps) {
        final st = stats[m.exerciseId]!;
        final agg = perMuscle.putIfAbsent(m.muscleId, _MuscleDayStats.new);
        agg.sets += st.setCount;
        agg.volume += m.contribution * st.volume;
        // e1RM stays unscaled — Phase 5's grade engine applies its own
        // bodyweight standards per muscle.
        agg.bestE1Rm = math.max(agg.bestE1Rm, st.bestE1Rm);
      }
      for (final e in perMuscle.entries) {
        await _db.muscleVolumeDaily.insertOnConflictUpdate(
          MuscleVolumeDailyCompanion.insert(
            userId: _userId,
            muscleId: e.key,
            date: start,
            totalSets: Value(e.value.sets),
            volume: Value(e.value.volume),
            bestE1Rm: Value(e.value.bestE1Rm),
          ),
        );
      }
    });
  }

  /// One-shot repair for data logged before rollups existed (or after a
  /// crash mid-write). No-op once any rollup row is present.
  Future<void> backfillIfNeeded() async {
    final done =
        await (_db.exerciseHistory.select()..limit(1)).getSingleOrNull();
    if (done == null) {
      final muscle =
          await (_db.muscleVolumeDaily.select()..limit(1)).getSingleOrNull();
      if (muscle == null) {
        final rows = await (_db.workoutSets.select()
              ..where((s) =>
                  s.isCompleted.equals(true) & s.loggedAt.isNotNull()))
            .get();
        final days = <DateTime>{
          for (final s in rows)
            if (s.loggedAt != null) dayOf(s.loggedAt!),
        };
        for (final d in days) {
          await recomputeDay(d);
        }
      }
    }
  }
}

class _ExDayStats {
  _ExDayStats({required this.setCount});

  final int setCount;
  double volume = 0;
  double bestE1Rm = 0;
  double topWeight = 0;
  int topReps = 0;
}

class _MuscleDayStats {
  int sets = 0;
  double volume = 0;
  double bestE1Rm = 0;
}
