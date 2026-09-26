import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../domain/analytics_math.dart';

const _userId = 'local';

/// Selected rolling window in weeks (4 / 12 / 26).
class AnalyticsPeriodNotifier extends Notifier<int> {
  @override
  int build() => 12;

  void set(int weeks) => state = weeks;
}

final analyticsPeriodProvider =
    NotifierProvider<AnalyticsPeriodNotifier, int>(
        AnalyticsPeriodNotifier.new);

/// Exercise picked in the strength chart (null → first with history).
class SelectedExerciseNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String id) => state = id;
}

final selectedExerciseProvider = NotifierProvider<SelectedExerciseNotifier,
    String?>(SelectedExerciseNotifier.new);

/// `ExerciseHistory` rows inside the selected window (day-level volumes).
final dailyVolumeProvider = StreamProvider.family<List<ExerciseHistoryData>, int>(
  (ref, weeks) {
    final db = ref.watch(databaseProvider);
    final since = periodStart(weeks, DateTime.now());
    final q = db.exerciseHistory.select()
      ..where((h) =>
          h.userId.equals(_userId) & h.date.isBiggerOrEqualValue(since))
      ..orderBy([(h) => OrderingTerm.asc(h.date)]);
    return q.watch();
  },
);

/// Finished-workout stats for the selected window; the streak looks at all
/// history (a streak isn't window-scoped).
class WorkoutStats {
  const WorkoutStats({
    required this.count,
    required this.days,
    required this.streak,
  });

  final int count; // finished workouts inside the window
  final Set<DateTime> days; // distinct midnight days inside the window
  final int streak; // consecutive weeks with ≥1 workout (all time)
}

final workoutStatsProvider = StreamProvider.family<WorkoutStats, int>(
  (ref, weeks) {
    final db = ref.watch(databaseProvider);
    final since = periodStart(weeks, DateTime.now());
    final now = DateTime.now();
    final q = db.workouts.select()
      ..where((w) => w.status.equals('completed'))
      ..orderBy([(w) => OrderingTerm.asc(w.startedAt)]);
    return q.watch().map((rows) {
      var count = 0;
      final days = <DateTime>{};
      final allDays = <DateTime>[];
      for (final w in rows) {
        final d = dayOf(w.startedAt);
        allDays.add(d);
        if (d.isBefore(since)) continue;
        count++;
        days.add(d);
      }
      return WorkoutStats(
        count: count,
        days: days,
        streak: weeklyStreak(allDays, now: now),
      );
    });
  },
);

/// Trained days for the consistency calendar, scoped to the selected
/// window (the grid sizes itself to the period; "All" scans history).
final calendarDaysProvider = StreamProvider<Set<DateTime>>((ref) {
  final weeks = ref.watch(analyticsPeriodProvider);
  final db = ref.watch(databaseProvider);
  final since = periodStart(weeks, DateTime.now());
  final q = db.workouts.select()
    ..where((w) =>
        w.status.equals('completed') &
        w.startedAt.isBiggerOrEqualValue(since));
  return q.watch().map((rows) => {for (final w in rows) dayOf(w.startedAt)});
});

/// Exercises with history rows in the window, ordered by name — powers the
/// strength chart's picker.
final historyExercisesProvider = StreamProvider.family<List<Exercise>, int>(
  (ref, weeks) {
    final db = ref.watch(databaseProvider);
    final since = periodStart(weeks, DateTime.now());
    final q = db.exerciseHistory.select()
      ..where((h) =>
          h.userId.equals(_userId) & h.date.isBiggerOrEqualValue(since));
    return q.watch().asyncMap((rows) async {
      final ids = rows.map((r) => r.exerciseId).toSet().toList()..sort();
      if (ids.isEmpty) return const <Exercise>[];
      final exercises = await (db.exercises.select()
            ..where((e) => e.id.isIn(ids) & e.deletedAt.isNull())
            ..orderBy([(e) => OrderingTerm.asc(e.name)]))
          .get();
      return exercises;
    });
  },
);

/// Day-level e1RM/top-set history for one exercise inside the window.
final exerciseTrendProvider = StreamProvider
    .family<List<ExerciseHistoryData>, ({String exerciseId, int weeks})>(
  (ref, args) {
    final db = ref.watch(databaseProvider);
    final since = periodStart(args.weeks, DateTime.now());
    final q = db.exerciseHistory.select()
      ..where((h) =>
          h.userId.equals(_userId) &
          h.exerciseId.equals(args.exerciseId) &
          h.date.isBiggerOrEqualValue(since))
      ..orderBy([(h) => OrderingTerm.asc(h.date)]);
    return q.watch();
  },
);

// ---------------------------------------------------------------------------
// Phase 5 — muscle grade board, heat map, balance ratios
// ---------------------------------------------------------------------------

/// Per-muscle aggregate over the rolling 30-day window, built from
/// `MuscleVolumeDaily` rollups.
class MuscleWindow {
  const MuscleWindow({
    required this.muscleId,
    required this.volumeKg,
    required this.totalSets,
    required this.bestE1Rm,
    required this.days,
    required this.lastTrained,
  });

  final String muscleId;
  final double volumeKg;
  final int totalSets;
  final double bestE1Rm;
  final Set<DateTime> days; // midnights inside the window
  final DateTime? lastTrained; // newest trained day (midnight)

  /// Hours since the last trained day's midnight — the shared freshness
  /// clock for the heat map and the consistency score (0 = trained today).
  double hoursSinceTrained(DateTime now) => lastTrained == null
      ? double.infinity
      : now.difference(lastTrained!).inMinutes / 60.0;
}

/// 30-day rollup window per muscle (userId = local).
final muscleWindowProvider = StreamProvider<Map<String, MuscleWindow>>((ref) {
  final db = ref.watch(databaseProvider);
  final since = addDays(dayOf(DateTime.now()), -29); // last 30 calendar days
  final q = db.muscleVolumeDaily.select()
    ..where((m) =>
        m.userId.equals(_userId) & m.date.isBiggerOrEqualValue(since));
  return q.watch().map((rows) {
    final volume = <String, double>{};
    final sets = <String, int>{};
    final best = <String, double>{};
    final days = <String, Set<DateTime>>{};
    final last = <String, DateTime>{};
    for (final r in rows) {
      volume[r.muscleId] = (volume[r.muscleId] ?? 0) + r.volume;
      sets[r.muscleId] = (sets[r.muscleId] ?? 0) + r.totalSets;
      if (r.bestE1Rm > (best[r.muscleId] ?? 0)) {
        best[r.muscleId] = r.bestE1Rm;
      }
      days.putIfAbsent(r.muscleId, () => <DateTime>{}).add(r.date);
      final cur = last[r.muscleId];
      if (cur == null || r.date.isAfter(cur)) last[r.muscleId] = r.date;
    }
    return {
      for (final id in volume.keys)
        id: MuscleWindow(
          muscleId: id,
          volumeKg: volume[id]!,
          totalSets: sets[id] ?? 0,
          bestE1Rm: best[id] ?? 0,
          days: days[id] ?? const {},
          lastTrained: last[id],
        ),
    };
  });
});

/// Σ 30-day volume for a list of muscles (muscles without data count 0).
double volumeOf(Map<String, MuscleWindow> window, List<String> muscleIds) =>
    muscleIds.fold(0.0, (sum, id) => sum + (window[id]?.volumeKg ?? 0));

/// One agonist/antagonist comparison, straight from the seed JSON.
class BalancePairConfig {
  const BalancePairConfig({
    required this.name,
    required this.aMuscles,
    required this.bMuscles,
    required this.targetMin,
    required this.targetMax,
  });

  factory BalancePairConfig.fromJson(Map<String, dynamic> json) =>
      BalancePairConfig(
        name: json['name'] as String,
        aMuscles: List<String>.from(json['a'] as List),
        bMuscles: List<String>.from(json['b'] as List),
        targetMin: (json['target_min'] as num).toDouble(),
        targetMax: (json['target_max'] as num).toDouble(),
      );

  final String name;
  final List<String> aMuscles;
  final List<String> bMuscles;
  final double targetMin;
  final double targetMax;
}

/// Balance pairs ship in the bundled seed (single source of truth).
final balancePairsProvider = FutureProvider<List<BalancePairConfig>>(
  (ref) async {
    final raw = await rootBundle.loadString('assets/seed/muscle_groups.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return [
      for (final p in json['balance_pairs'] as List)
        BalancePairConfig.fromJson(p as Map<String, dynamic>),
    ];
  },
);
