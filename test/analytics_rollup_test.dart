import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/database/seed_service.dart';
import 'package:kinetic/features/analytics/application/rollup_service.dart';
import 'package:kinetic/features/analytics/domain/analytics_math.dart';
import 'package:kinetic/features/analytics/domain/grade_engine.dart';
import 'package:kinetic/features/workout/application/workout_session_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // rootBundle for seeding
  late AppDatabase db;
  late ProviderContainer container;
  late RollupService rollups;
  var seq = 0;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await SeedService(db).ensureSeeded();
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    rollups = RollupService(db);
    await container.read(workoutSessionProvider.future);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  /// One finished workout on [day] carrying a single completed set.
  Future<String> seedSet({
    required DateTime day,
    required String exerciseId,
    double? weightKg,
    int? reps,
    String setType = 'working',
  }) async {
    final workoutId = 'w-${seq++}';
    final setId = 's-$workoutId';
    await db.workouts.insertOnConflictUpdate(WorkoutsCompanion.insert(
      id: workoutId,
      userId: 'local',
      startedAt: day,
      status: const Value('completed'),
      endedAt: Value(day.add(const Duration(hours: 1))),
      durationSec: const Value(3600),
      totalVolume: const Value(0),
      updatedAt: day,
    ));
    await db.workoutSets.insertOnConflictUpdate(WorkoutSetsCompanion.insert(
      id: setId,
      workoutId: workoutId,
      exerciseId: exerciseId,
      orderIndex: 0,
      setType: Value(setType),
      weightKg: Value(weightKg),
      reps: Value(reps),
      isCompleted: const Value(true),
      loggedAt: Value(day),
      updatedAt: day,
    ));
    return setId;
  }

  Future<ExerciseHistoryData?> history(DateTime day, String exerciseId) =>
      (db.exerciseHistory.select()
            ..where((h) =>
                h.date.equals(dayOf(day)) & h.exerciseId.equals(exerciseId)))
          .getSingleOrNull();

  Future<List<MuscleVolumeDailyData>> muscleRows(DateTime day) =>
      (db.muscleVolumeDaily.select()
            ..where((m) => m.date.equals(dayOf(day)))
            ..orderBy([(m) => OrderingTerm.asc(m.muscleId)]))
          .get();

  WorkoutSessionNotifier notifier() =>
      container.read(workoutSessionProvider.notifier);

  group('recomputeDay', () {
    test('builds exercise history and contribution-weighted muscle rows',
        () async {
      final day = DateTime(2026, 9, 20, 10, 30);
      await seedSet(
          day: day, exerciseId: 'barbell-bench-press', weightKg: 60, reps: 5);
      await seedSet(
          day: day,
          exerciseId: 'barbell-bench-press',
          weightKg: 62.5,
          reps: 5,
          setType: 'warmup');
      await seedSet(
          day: day, exerciseId: 'barbell-row', weightKg: 50, reps: 8);

      await rollups.recomputeDay(day);

      // Warm-up excluded from volume AND from the top set (62.5 > 60).
      final bench = await history(day, 'barbell-bench-press');
      expect(bench, isNotNull);
      expect(bench!.totalVolume, closeTo(300, 0.001));
      expect(bench.bestE1Rm, closeTo(GradeEngine.epley1Rm(60, 5), 0.001));
      expect(bench.topWeight, 60);
      expect(bench.topReps, 5);

      final row = await history(day, 'barbell-row');
      expect(row, isNotNull);
      expect(row!.totalVolume, closeTo(400, 0.001));

      // Muscle rows must satisfy: volume = Σ contribution × exercise volume,
      // sets = Σ counted sets, best e1RM = max over the mapped exercises.
      final maps = await db.exerciseMuscleMap.select().get();
      final exVolume = {
        'barbell-bench-press': 300.0,
        'barbell-row': 400.0,
      };
      final exSets = {'barbell-bench-press': 1, 'barbell-row': 1};
      final exBest = {
        'barbell-bench-press': GradeEngine.epley1Rm(60, 5),
        'barbell-row': GradeEngine.epley1Rm(50, 8),
      };

      final rows = await muscleRows(day);
      expect(rows, isNotEmpty);
      expect(rows.map((m) => m.muscleId), contains('chest'));

      for (final m in rows) {
        var volume = 0.0;
        var sets = 0;
        var best = 0.0;
        for (final map in maps.where((x) => x.muscleId == m.muscleId)) {
          if (!exVolume.containsKey(map.exerciseId)) continue;
          volume += map.contribution * exVolume[map.exerciseId]!;
          sets += exSets[map.exerciseId]!;
          if (exBest[map.exerciseId]! > best) best = exBest[map.exerciseId]!;
        }
        expect(m.volume, closeTo(volume, 0.001),
            reason: 'volume of ${m.muscleId}');
        expect(m.totalSets, sets, reason: 'sets of ${m.muscleId}');
        expect(m.bestE1Rm, closeTo(best, 0.001),
            reason: 'bestE1Rm of ${m.muscleId}');
      }

      // Bench's chest work is attributed to the chest at full share.
      final chest = rows.firstWhere((m) => m.muscleId == 'chest');
      expect(chest.volume, greaterThan(0));
      expect(chest.totalSets, 1); // warm-up set not counted
    });

    test('is idempotent — re-running changes nothing', () async {
      final day = DateTime(2026, 9, 21, 9);
      await seedSet(
          day: day, exerciseId: 'barbell-bench-press', weightKg: 60, reps: 5);
      await seedSet(
          day: day, exerciseId: 'barbell-bench-press', weightKg: 70, reps: 3);

      await rollups.recomputeDay(day);
      final firstHistory = await history(day, 'barbell-bench-press');
      final firstMuscle = await muscleRows(day);

      await rollups.recomputeDay(day);
      final secondHistory = await history(day, 'barbell-bench-press');
      final secondMuscle = await muscleRows(day);

      expect(secondHistory!.totalVolume, firstHistory!.totalVolume);
      expect(secondHistory.totalVolume, closeTo(510, 0.001)); // 300 + 210
      expect(secondHistory.bestE1Rm, firstHistory.bestE1Rm);
      expect(secondMuscle, hasLength(firstMuscle.length));
      for (var i = 0; i < firstMuscle.length; i++) {
        expect(secondMuscle[i].volume, firstMuscle[i].volume);
        expect(secondMuscle[i].totalSets, firstMuscle[i].totalSets);
      }
    });

    test('only touches the requested day', () async {
      final dayA = DateTime(2026, 9, 19, 9);
      final dayB = DateTime(2026, 9, 20, 9);
      await seedSet(
          day: dayA, exerciseId: 'barbell-bench-press', weightKg: 60, reps: 5);
      await seedSet(
          day: dayB, exerciseId: 'barbell-bench-press', weightKg: 70, reps: 3);

      await rollups.recomputeDay(dayB);

      expect(await history(dayA, 'barbell-bench-press'), isNull);
      expect(await muscleRows(dayA), isEmpty);
      expect(
        (await history(dayB, 'barbell-bench-press'))!.totalVolume,
        closeTo(210, 0.001),
      );

      await rollups.recomputeDay(dayA);
      expect(
        (await history(dayA, 'barbell-bench-press'))!.totalVolume,
        closeTo(300, 0.001),
      );
    });

    test('warm-ups out; drop and failure in; e1RM only for reps ≤ 10',
        () async {
      final day = DateTime(2026, 9, 22, 9);
      // Would win the e1RM race (103.3) if warm-ups leaked in.
      await seedSet(
          day: day,
          exerciseId: 'barbell-bench-press',
          weightKg: 100,
          reps: 1,
          setType: 'warmup');
      await seedSet(
          day: day,
          exerciseId: 'barbell-bench-press',
          weightKg: 80,
          reps: 6,
          setType: 'drop');
      await seedSet(
          day: day,
          exerciseId: 'barbell-bench-press',
          weightKg: 90,
          reps: 5,
          setType: 'failure');

      await rollups.recomputeDay(day);
      final row = await history(day, 'barbell-bench-press');
      expect(row!.totalVolume, closeTo(480 + 450, 0.001)); // no 100×1
      expect(row.bestE1Rm, closeTo(GradeEngine.epley1Rm(90, 5), 0.001));
      expect(row.topWeight, 90);
      expect(row.topReps, 5);

      // High-rep sets contribute volume but never an e1RM.
      final day2 = DateTime(2026, 9, 23, 9);
      await seedSet(
          day: day2, exerciseId: 'barbell-bench-press', weightKg: 60, reps: 15);
      await rollups.recomputeDay(day2);
      final highRep = await history(day2, 'barbell-bench-press');
      expect(highRep!.totalVolume, closeTo(900, 0.001));
      expect(highRep.bestE1Rm, 0);
    });

    test('duration-only sets skip history but still credit muscle sets',
        () async {
      final day = DateTime(2026, 9, 24, 9);
      await seedSet(day: day, exerciseId: 'plank'); // no weight, no reps

      await rollups.recomputeDay(day);

      expect(await history(day, 'plank'), isNull);
      final rows = await muscleRows(day);
      expect(rows, isNotEmpty);
      expect(rows.every((m) => m.volume == 0), isTrue);
      expect(rows.any((m) => m.totalSets >= 1), isTrue);
    });
  });

  group('session integration', () {
    test('logSet → updateSet → deleteSet keep rollups fresh', () async {
      await notifier().startWorkout();
      final set = await notifier()
          .logSet(exerciseId: 'barbell-bench-press', weightKg: 60, reps: 5);

      final today = dayOf(DateTime.now());
      var row = await history(today, 'barbell-bench-press');
      expect(row, isNotNull);
      expect(row!.totalVolume, closeTo(300, 0.001));

      await notifier().updateSet(set.id, weightKg: 70);
      row = await history(today, 'barbell-bench-press');
      expect(row!.totalVolume, closeTo(350, 0.001));

      await notifier().deleteSet(set.id);
      expect(await history(today, 'barbell-bench-press'), isNull);
    });

    test('removeExercise rolls back its day', () async {
      await notifier().startWorkout();
      await notifier()
          .logSet(exerciseId: 'barbell-bench-press', weightKg: 60, reps: 5);
      final today = dayOf(DateTime.now());
      expect(await history(today, 'barbell-bench-press'), isNotNull);

      await notifier().removeExercise('barbell-bench-press');
      expect(await history(today, 'barbell-bench-press'), isNull);
    });
  });

  group('backfillIfNeeded', () {
    test('fills pre-rollup days once, then leaves the guard closed', () async {
      final day1 = DateTime(2026, 9, 18, 9);
      await seedSet(
          day: day1, exerciseId: 'barbell-bench-press', weightKg: 60, reps: 5);
      await rollups.backfillIfNeeded();
      expect(await history(day1, 'barbell-bench-press'), isNotNull);

      // Guard is closed once any rollup row exists (documented behavior)…
      final day2 = DateTime(2026, 9, 19, 9);
      await seedSet(
          day: day2, exerciseId: 'barbell-bench-press', weightKg: 70, reps: 3);
      await rollups.backfillIfNeeded();
      expect(await history(day2, 'barbell-bench-press'), isNull);

      // …and an explicit recompute catches the gap up.
      await rollups.recomputeDay(day2);
      expect(
        (await history(day2, 'barbell-bench-press'))!.totalVolume,
        closeTo(210, 0.001),
      );
    });

    test('is a no-op on a fresh database', () async {
      await rollups.backfillIfNeeded(); // no sets at all → no error
      expect(await db.select(db.exerciseHistory).get(), isEmpty);
    });
  });
}
