import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/utils/day_key.dart';
import '../health/health_providers.dart';
import '../nutrition/application/nutrition_providers.dart';
import '../nutrition/domain/food_math.dart';
import '../workout/application/workout_session_notifier.dart';
import 'domain/day_history.dart';

/// Latest weigh-in strictly before [dayKey] (its row id ascends with the
/// date, so ordering by id is ordering by day) — shared by the History
/// fetch (burn fallback + delta) and the workout-detail burn line.
Future<BodyMetric?> weighInBefore(AppDatabase db, String dayKey) =>
    (db.bodyMetrics.select()
          ..where((b) =>
              b.id.isSmallerThanValue(dayKey) &
              b.weightKg.isNotNull() &
              b.deletedAt.isNull())
          ..orderBy([(b) => OrderingTerm.desc(b.id)])
          ..limit(1))
        .getSingleOrNull();

/// Everything recorded on [dayKey] (Round 10 History) — one fetch that
/// assembles body metrics, food logs and finished sessions.
///
/// Invalidation rides on the existing providers ([dayMetricProvider],
/// [foodLogsProvider], [workoutSessionProvider]) so an edit on Diet, a
/// weigh-in on Profile, or finishing a session on the logger re-runs this
/// future without polling. All heavy lifting is plain one-shot reads —
/// History pages are read-mostly.
final dayHistoryProvider =
    FutureProvider.family<DayHistory, String>((ref, dayKey) async {
  final db = ref.watch(databaseProvider);
  // Invalidation hooks (see doc comment): changes re-run this fetch.
  ref.watch(dayMetricProvider(dayKey));
  ref.watch(foodLogsProvider(dayKey));
  ref.watch(workoutSessionProvider);

  final metric = await (db.bodyMetrics.select()
        ..where((b) => b.id.equals(dayKey)))
      .getSingleOrNull();

  final logs = await (db.foodLogs.select()
        ..where((l) => l.dayKey.equals(dayKey) & l.deletedAt.isNull())
        ..orderBy([(l) => OrderingTerm.desc(l.loggedAt)]))
      .get();

  // Latest weigh-in strictly before this day — burn fallback + delta.
  final prevWeigh = await weighInBefore(db, dayKey);

  // Finished sessions started this local day (instant range on startedAt
  // matches the house dayOf() bucketing: startedAt is a local wall-clock
  // instant; dayStart..dayEnd is exactly that calendar day).
  final dayStart = parseDayKey(dayKey);
  final dayEnd = dayStart.add(const Duration(days: 1));
  final workouts = await (db.workouts.select()
        ..where((w) =>
            w.status.equals('completed') &
            w.deletedAt.isNull() &
            w.startedAt.isBiggerOrEqualValue(dayStart) &
            w.startedAt.isSmallerThanValue(dayEnd))
        ..orderBy([(w) => OrderingTerm.desc(w.startedAt)]))
      .get();

  // One sets query for the whole day: completed count + cardio seconds.
  var setsByWorkout = <String, List<WorkoutSet>>{};
  if (workouts.isNotEmpty) {
    final ids = workouts.map((w) => w.id).toList();
    final sets = await (db.workoutSets.select()
          ..where((s) => s.workoutId.isIn(ids) & s.deletedAt.isNull()))
        .get();
    setsByWorkout = {};
    for (final s in sets) {
      setsByWorkout.putIfAbsent(s.workoutId, () => []).add(s);
    }
  }

  // Routine names (deleted routines fall back to 'Workout').
  Map<String, String> routineNames = {};
  final routineIds = {
    for (final w in workouts)
      if (w.routineId != null) w.routineId!,
  };
  if (routineIds.isNotEmpty) {
    final routines = await (db.routines.select()
          ..where((r) =>
              r.id.isIn(routineIds.toList()) & r.deletedAt.isNull()))
        .get();
    routineNames = {for (final r in routines) r.id: r.name};
  }

  final burnWeight = metric?.weightKg ?? prevWeigh?.weightKg;
  final dayWorkouts = <DayWorkout>[
    for (final w in workouts)
      DayWorkout(
        workout: w,
        routineName: w.routineId == null
            ? 'Workout'
            : routineNames[w.routineId] ?? 'Workout',
        setCount: (setsByWorkout[w.id] ?? const <WorkoutSet>[])
            .where((s) => s.isCompleted)
            .length,
        cardioSec: (setsByWorkout[w.id] ?? const <WorkoutSet>[])
            .where((s) => s.isCompleted && s.setType == 'cardio')
            .fold<int>(0, (a, s) => a + (s.durationSec ?? 0)),
        kcalBurn: burnWeight == null
            ? 0
            : workoutBurnKcal(
                w.durationSec ?? w.endedAt?.difference(w.startedAt).inSeconds ?? 0,
                burnWeight,
              ),
      ),
  ];

  return DayHistory(
    dayKey: dayKey,
    weightKg: metric?.weightKg,
    prevWeightKg: prevWeigh?.weightKg,
    prevWeightDay: prevWeigh?.id,
    steps: metric?.steps,
    waterMl: metric?.waterMl,
    foodLogs: logs,
    totals: sum(logs),
    workouts: dayWorkouts,
  );
});

/// Body-metric rows for the 7 calendar days ending at [key], oldest
/// first — the sparkline feed (missing days simply have no row).
final weekBodyMetricsProvider =
    FutureProvider.family<List<BodyMetric>, String>((ref, key) async {
  final db = ref.watch(databaseProvider);
  final end = parseDayKey(key);
  final start = end.subtract(const Duration(days: 6));
  final rows = await (db.bodyMetrics.select()
        ..where((b) =>
            b.id.isBiggerOrEqualValue(dayKey(start)) &
            b.id.isSmallerOrEqualValue(key) &
            b.deletedAt.isNull())
        ..orderBy([(b) => OrderingTerm.asc(b.id)]))
      .get();
  return rows;
});
