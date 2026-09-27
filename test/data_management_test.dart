import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show AsyncProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/database/delete_service.dart';
import 'package:kinetic/core/database/seed_service.dart';
import 'package:kinetic/core/export/export_service.dart';
import 'package:kinetic/core/export/import_service.dart';
import 'package:kinetic/features/analytics/application/analytics_providers.dart';
import 'package:kinetic/features/analytics/application/rollup_service.dart';
import 'package:kinetic/features/profile/body_metric_log.dart';
import 'package:kinetic/features/routines/application/routine_repository.dart';

/// Profile → Data: JSON import (replace-all) and the scoped deletes.
///
/// Every delete asserts the same contract: the targeted rows go, the
/// untouched tables stay, and the analytics rollups recompute so Home /
/// Analytics / heat map never disagree with the raw tables.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late ProviderContainer container;
  late RollupService rollups;
  var seq = 0;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await SeedService(db).ensureSeeded();
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    rollups = RollupService(db);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  /// Riverpod 3 won't start a StreamProvider without a listener, so listen
  /// first, await the first emission, then unsubscribe.
  Future<T> first<T>(AsyncProviderListenable<T> provider) async {
    final sub = container.listen(provider, (_, _) {});
    final value = await container.read(provider.future);
    sub.close();
    return value;
  }

  /// One finished workout on [day] with the given completed hard sets
  /// (exercise, kg, reps) plus its analytics rollups — what logging a
  /// session leaves behind.
  Future<String> seedWorkout(
    DateTime day, {
    String? routineId,
    List<(String, double, int)> sets = const [
      ('barbell-bench-press', 60, 5),
    ],
  }) async {
    final workoutId = 'w-${seq++}';
    final total = sets.fold<double>(0, (a, s) => a + s.$2 * s.$3);
    await db.workouts.insertOnConflictUpdate(WorkoutsCompanion.insert(
      id: workoutId,
      userId: 'local',
      startedAt: day,
      status: const Value('completed'),
      routineId: Value(routineId),
      endedAt: Value(day.add(const Duration(hours: 1))),
      durationSec: const Value(3600),
      totalVolume: Value(total),
      updatedAt: day,
    ));
    for (var i = 0; i < sets.length; i++) {
      final (exerciseId, weight, reps) = sets[i];
      await db.workoutSets.insertOnConflictUpdate(WorkoutSetsCompanion.insert(
        id: 's-$workoutId-$i',
        workoutId: workoutId,
        exerciseId: exerciseId,
        orderIndex: i,
        setType: const Value('working'),
        weightKg: Value(weight),
        reps: Value(reps),
        isCompleted: const Value(true),
        loggedAt: Value(day),
        updatedAt: day,
      ));
    }
    await rollups.recomputeDay(day);
    return workoutId;
  }

  Future<String> seedRoutine() => RoutineRepository(db).saveRoutine(
        name: 'Push Day',
        entries: const [
          RoutineDraft(
            exerciseId: 'barbell-bench-press',
            targetSets: 3,
            targetReps: 5,
            targetWeight: 60,
          ),
        ],
      );

  Future<void> seedCustomExercise() =>
      db.exercises.insertOnConflictUpdate(ExercisesCompanion.insert(
        id: 'custom-tilt-row',
        name: 'Tilt Row',
        mechanics: 'isolation',
        primaryMuscleId: 'lats',
        isCustom: const Value(true),
        updatedAt: DateTime(2026, 9, 20),
      ));

  group('import', () {
    test('JSON backup round-trips rows, rollups and stats', () async {
      final day = DateTime(2026, 9, 20, 10);
      final routineId = await seedRoutine();
      await seedWorkout(
        day,
        routineId: routineId,
        sets: const [
          ('barbell-bench-press', 60, 5), // 300
          ('barbell-row', 50, 8), // 400
        ],
      );

      final exercisesBefore = (await db.select(db.exercises).get()).length;
      final json = await ExportService(db).buildJson();

      // Simulate a fresh install: history gone, catalog intact.
      await DeleteService(db).deleteWorkoutHistory();
      expect(await db.select(db.workouts).get(), isEmpty);
      expect(await db.select(db.exerciseHistory).get(), isEmpty);

      final summary = await ImportService(db).importJson(json);
      expect(summary.workouts, 1);
      expect(summary.sets, 2);
      expect(summary.routines, 1);
      expect(summary.profileRestored, isFalse);

      // Rows restored verbatim.
      final workouts = await db.select(db.workouts).get();
      expect(workouts.single.status, 'completed');
      expect(workouts.single.routineId, routineId);
      expect(workouts.single.totalVolume, closeTo(700, 0.001));
      expect(await db.select(db.workoutSets).get(), hasLength(2));
      expect(await db.select(db.routines).get(), hasLength(1));
      expect(await db.select(db.routineExercises).get(), hasLength(1));
      expect((await db.select(db.exercises).get()).length, exercisesBefore);

      // Rollups rebuilt for the restored day — Analytics agrees again.
      final history = await db.select(db.exerciseHistory).get();
      expect(
        history.map((h) => h.exerciseId).toSet(),
        containsAll(['barbell-bench-press', 'barbell-row']),
      );
      expect(await db.select(db.muscleVolumeDaily).get(), isNotEmpty);

      final stats = await first(workoutStatsProvider(12));
      expect(stats.count, 1);
    });

    test('a pre-v3 backup (no count/rest keys) still imports', () async {
      // Exactly what Round 2's exporter wrote: entries carry the v1/v2
      // isWarmup flag and the un-editable 90 s placeholder, exercises have
      // no rest column at all.
      const legacy = '''
      {
        "app": "kinetic",
        "format": 1,
        "exportedAt": "2026-09-01T10:00:00.000",
        "exercises": [
          {
            "id": "cus_legacy",
            "name": "Old Lift",
            "mechanics": "compound",
            "category": "custom",
            "primaryMuscleId": "chest",
            "equipment": "[]",
            "defaultMetric": "weight_reps",
            "animationKind": "none",
            "isCustom": true,
            "ownerId": "local",
            "updatedAt": "2026-09-01T10:00:00.000"
          }
        ],
        "routines": [
          {
            "id": "r1",
            "userId": "local",
            "name": "Legacy Day",
            "orderIndex": 0,
            "updatedAt": "2026-09-01T10:00:00.000",
            "entries": [
              {
                "id": "e1",
                "routineId": "r1",
                "exerciseId": "cus_legacy",
                "orderIndex": 0,
                "targetSets": 2,
                "targetReps": 10,
                "restSeconds": 90,
                "isWarmup": true,
                "updatedAt": "2026-09-01T10:00:00.000"
              },
              {
                "id": "e2",
                "routineId": "r1",
                "exerciseId": "barbell-row",
                "orderIndex": 1,
                "targetSets": 3,
                "targetReps": 8,
                "restSeconds": 90,
                "isWarmup": false,
                "updatedAt": "2026-09-01T10:00:00.000"
              }
            ]
          }
        ],
        "workouts": []
      }
      ''';

      final summary = await ImportService(db).importJson(legacy);
      expect(summary.exercises, 1);
      expect(summary.routines, 1);

      final slots = await (db.routineExercises.select()
            ..orderBy([(e) => OrderingTerm.asc(e.orderIndex)]))
          .get();
      expect(slots, hasLength(2));

      // The whole-entry warm-up flag becomes a warm-up count…
      expect(slots[0].targetSets, 2);
      expect(slots[0].warmupSets, 2);
      expect(slots[0].dropSets, 0);
      expect(slots[0].failureSets, 0);
      expect(slots[0].isWarmup, isTrue);
      // …and the placeholder 90 becomes "inherit".
      expect(slots[0].restSeconds, inheritRestSeconds);

      expect(slots[1].warmupSets, 0);
      expect(slots[1].restSeconds, inheritRestSeconds);

      // Exercises import with no rest override.
      final ex = await (db.exercises.select()
            ..where((e) => e.id.equals('cus_legacy')))
          .getSingle();
      expect(ex.restSeconds, isNull);
    });

    test('Your data profile fields survive export → import', () async {
      await db.profiles.insertOnConflictUpdate(ProfilesCompanion.insert(
        id: 'local',
        username: const Value('Pio'),
        bodyweightKg: const Value(82.5),
        heightCm: const Value(181),
        birthDate: const Value('1996-03-04'),
        sex: const Value('other'),
        bodyFatPct: const Value(14.5),
        trainingGoal: const Value('hypertrophy'),
        updatedAt: DateTime(2026, 9, 20),
      ));
      final json = await ExportService(db).buildJson();

      // Fresh install, then restore the backup.
      await DeleteService(db).deleteAllData();
      final summary = await ImportService(db).importJson(json);
      expect(summary.profileRestored, isTrue);

      final profile = await (db.profiles.select()
            ..where((p) => p.id.equals('local')))
          .getSingle();
      expect(profile.username, 'Pio');
      expect(profile.bodyweightKg, 82.5);
      expect(profile.heightCm, 181);
      expect(profile.birthDate, '1996-03-04');
      expect(profile.sex, 'other');
      expect(profile.bodyFatPct, 14.5);
      expect(profile.trainingGoal, 'hypertrophy');
    });

    test('weight-trend rows survive export → import', () async {
      await logBodyWeight(db, 82.5, now: DateTime(2026, 9, 20));
      await logBodyWeight(db, 82.1, now: DateTime(2026, 9, 21));
      final json = await ExportService(db).buildJson();

      // Fresh install, then restore the backup.
      await DeleteService(db).deleteAllData();
      expect(await db.bodyMetrics.select().get(), isEmpty);

      await ImportService(db).importJson(json);
      final rows = await (db.bodyMetrics.select()
            ..orderBy([(m) => OrderingTerm.asc(m.id)]))
          .get();
      expect(rows, hasLength(2));
      expect(rows.map((m) => m.id), ['2026-09-20', '2026-09-21']);
      expect(rows.map((m) => m.weightKg), [82.5, 82.1]);
    });

    test('a pre-Round-5 profile backup (no Your data keys) still restores',
        () async {
      // Exactly what Round 4's exporter wrote for the profile row.
      const legacy = '''
      {
        "app": "kinetic",
        "format": 1,
        "exportedAt": "2026-09-01T10:00:00.000",
        "profile": {
          "id": "local",
          "username": "old",
          "unitSystem": "kg",
          "theme": "dark",
          "bodyweightKg": 70.0,
          "updatedAt": "2026-09-01T10:00:00.000"
        },
        "exercises": [],
        "routines": [],
        "workouts": []
      }
      ''';

      final summary = await ImportService(db).importJson(legacy);
      expect(summary.profileRestored, isTrue);

      final profile = await (db.profiles.select()
            ..where((p) => p.id.equals('local')))
          .getSingle();
      expect(profile.username, 'old');
      expect(profile.bodyweightKg, 70.0);
      // New columns read NULL until the user fills them in.
      expect(profile.heightCm, isNull);
      expect(profile.birthDate, isNull);
      expect(profile.sex, isNull);
      expect(profile.bodyFatPct, isNull);
      expect(profile.trainingGoal, isNull);
    });

    test('invalid backups are rejected before anything is written',
        () async {
      await seedWorkout(DateTime(2026, 9, 20, 10));

      expect(
        () => ImportService.parse('not json'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => ImportService.parse('{"app":"strava","format":1}'),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('Kinetic backup'),
        )),
      );
      expect(
        () => ImportService.parse(
          '{"app":"kinetic","format":99,'
          '"exercises":[],"routines":[],"workouts":[]}',
        ),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('newer version'),
        )),
      );

      // A failed import leaves existing data untouched.
      await expectLater(
        ImportService(db).importJson('oops'),
        throwsA(isA<FormatException>()),
      );
      expect(await db.select(db.workouts).get(), hasLength(1));
    });
  });

  group('delete', () {
    test('deleteWorkoutHistory clears history, keeps a live session and '
        'everything else', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      await seedWorkout(today.add(const Duration(hours: 10)));
      final routineId = await seedRoutine();
      final exercisesBefore = (await db.select(db.exercises).get()).length;

      // An in-progress session — its workout row and completed set must
      // survive, and so must its rollup contribution.
      await db.workouts.insertOnConflictUpdate(WorkoutsCompanion.insert(
        id: 'active-w',
        userId: 'local',
        startedAt: now,
        status: const Value('active'),
        updatedAt: now,
      ));
      await db.workoutSets.insertOnConflictUpdate(WorkoutSetsCompanion.insert(
        id: 'active-s',
        workoutId: 'active-w',
        exerciseId: 'barbell-row',
        orderIndex: 0,
        weightKg: const Value(50),
        reps: const Value(8),
        isCompleted: const Value(true),
        loggedAt: Value(now),
        updatedAt: now,
      ));
      await rollups.recomputeDay(today);

      await DeleteService(db).deleteWorkoutHistory();

      // Finished rows gone, the live session untouched.
      final workouts = await db.select(db.workouts).get();
      expect(workouts, hasLength(1));
      expect(workouts.single.id, 'active-w');
      expect(
        (await db.select(db.workoutSets).get()).map((s) => s.id),
        ['active-s'],
      );

      // Rollups rebuilt from what remains: bench (finished) wiped from
      // today's history, barbell-row (live session) kept.
      final history = await db.select(db.exerciseHistory).get();
      expect(history.map((h) => h.exerciseId).toSet(), {'barbell-row'});
      final muscles = (await db.select(db.muscleVolumeDaily).get())
          .map((m) => m.muscleId)
          .toSet();
      expect(muscles, contains('lats'));
      expect(muscles, isNot(contains('chest')));

      // Routines, slots and the catalog stay.
      expect(await db.select(db.routines).get(), hasLength(1));
      expect(await db.select(db.routineExercises).get(), hasLength(1));
      expect((await db.select(db.exercises).get()).length, exercisesBefore);
      expect(routineId, isNotEmpty);
    });

    test('deleteRoutines keeps workout history', () async {
      await seedWorkout(DateTime(2026, 9, 20, 10));
      await seedRoutine();

      await DeleteService(db).deleteRoutines();

      expect(await db.select(db.routines).get(), isEmpty);
      expect(await db.select(db.routineExercises).get(), isEmpty);
      expect(await db.select(db.workouts).get(), hasLength(1));
      expect(await db.select(db.workoutSets).get(), isNotEmpty);
      expect(await db.select(db.exerciseHistory).get(), isNotEmpty);
      expect(await db.select(db.exercises).get(), isNotEmpty);
    });

    test('deleteCustomExercises removes sets, history and repairs totals',
        () async {
      final day = DateTime(2026, 9, 20, 10);
      await seedCustomExercise();
      await db.exerciseMuscleMap.insertOnConflictUpdate(
        ExerciseMuscleMapCompanion.insert(
          exerciseId: 'custom-tilt-row',
          muscleId: 'lats',
        ),
      );
      await seedWorkout(day, sets: const [
        ('custom-tilt-row', 60, 5), // 300 — goes away with the exercise
        ('barbell-bench-press', 60, 5), // 300 — stays
      ]);

      expect(
        (await db.select(db.exerciseHistory).get())
            .map((h) => h.exerciseId),
        contains('custom-tilt-row'),
      );

      await DeleteService(db).deleteCustomExercises();

      // The exercise and every reference to it are gone…
      final exercises = await db.select(db.exercises).get();
      expect(exercises.map((e) => e.id), isNot(contains('custom-tilt-row')));
      expect(exercises.map((e) => e.id), contains('barbell-bench-press'));
      expect(
        (await db.select(db.workoutSets).get()).map((s) => s.exerciseId),
        {'barbell-bench-press'},
      );
      expect(
        (await db.select(db.exerciseHistory).get())
            .map((h) => h.exerciseId),
        isNot(contains('custom-tilt-row')),
      );
      expect(
        (await db.select(db.exerciseMuscleMap).get())
            .map((m) => m.exerciseId),
        isNot(contains('custom-tilt-row')),
      );

      // …the workout total was repaired to what remains (300 kg)…
      final workout = (await db.select(db.workouts).get()).single;
      expect(workout.totalVolume, closeTo(300, 0.001));

      // …and the day's muscle rollup dropped the deleted exercise's muscle
      // while keeping the seeded bench's chest row.
      final muscles = (await db.select(db.muscleVolumeDaily).get())
          .map((m) => m.muscleId)
          .toSet();
      expect(muscles, contains('chest'));
      expect(muscles, isNot(contains('lats')));
    });

    test('deleteAllData wipes everything and reseeds the catalog', () async {
      final day = DateTime(2026, 9, 20, 10);
      await seedWorkout(day);
      await seedRoutine();
      await seedCustomExercise();
      await db.profiles.insertOnConflictUpdate(ProfilesCompanion.insert(
        id: 'local',
        username: const Value('gudiya'),
        updatedAt: DateTime(2026, 9, 20),
      ));
      await logBodyWeight(db, 82.5, now: DateTime(2026, 9, 20));

      await DeleteService(db).deleteAllData();

      // Every user-owned table is empty…
      expect(await db.select(db.workouts).get(), isEmpty);
      expect(await db.select(db.workoutSets).get(), isEmpty);
      expect(await db.select(db.routines).get(), isEmpty);
      expect(await db.select(db.routineExercises).get(), isEmpty);
      expect(await db.select(db.exerciseHistory).get(), isEmpty);
      expect(await db.select(db.muscleVolumeDaily).get(), isEmpty);
      expect(await db.select(db.bodyMetrics).get(), isEmpty);
      expect(await db.select(db.profiles).get(), isEmpty);

      // …while the bundled catalogs come back, without custom rows.
      final exercises = await db.select(db.exercises).get();
      expect(exercises, isNotEmpty);
      expect(exercises.map((e) => e.id), contains('barbell-bench-press'));
      expect(exercises.where((e) => e.isCustom), isEmpty);
      expect(await db.select(db.muscleGroups).get(), isNotEmpty);
    });
  });
}
