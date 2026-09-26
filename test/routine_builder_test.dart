import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/database/seed_service.dart';
import 'package:kinetic/features/routines/application/routine_providers.dart';
import 'package:kinetic/features/routines/application/routine_repository.dart';
import 'package:kinetic/features/workout/application/workout_session_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late ProviderContainer container;
  late RoutineRepository repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await SeedService(db).ensureSeeded();
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    // Initialize the AsyncNotifier so methods can read state immediately.
    await container.read(workoutSessionProvider.future);
    repo = RoutineRepository(db);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  WorkoutSessionNotifier session() =>
      container.read(workoutSessionProvider.notifier);
  Future<WorkoutSession?> readSession() =>
      container.read(workoutSessionProvider.future);

  RoutineDraft draft(
    String id, {
    int sets = 3,
    int reps = 8,
    double? weight,
    bool linkNext = false,
    bool warmup = false,
    int warmupSets = 0,
    int dropSets = 0,
    int failureSets = 0,
    int restSeconds = inheritRestSeconds,
  }) =>
      RoutineDraft(
        exerciseId: id,
        targetSets: sets,
        targetReps: reps,
        targetWeight: weight,
        linkNext: linkNext,
        // `warmup: true` = the v1/v2 "whole entry is warm-up" flag, now
        // expressed as a count of `sets`.
        warmupSets: warmup ? sets : warmupSets,
        dropSets: dropSets,
        failureSets: failureSets,
        restSeconds: restSeconds,
      );

  group('saveRoutine', () {
    test('creates routine + targeted children with superset groups', () async {
      final id = await repo.saveRoutine(name: 'Upper', entries: [
        draft('barbell-back-squat',
            sets: 1, reps: 5, weight: 40, warmup: true),
        draft('barbell-bench-press',
            sets: 3, reps: 8, weight: 60, linkNext: true),
        draft('barbell-row', sets: 3, reps: 8, weight: 50, linkNext: true),
        draft('pull-up', sets: 3, reps: 10),
      ]);

      final routine =
          await (db.routines.select()..where((r) => r.id.equals(id)))
              .getSingle();
      expect(routine.name, 'Upper');
      expect(routine.deletedAt, isNull);

      final rows = await (db.routineExercises.select()
            ..where((e) => e.routineId.equals(id))
            ..orderBy([(e) => OrderingTerm.asc(e.orderIndex)]))
          .get();
      expect(rows, hasLength(4));
      expect(rows.map((r) => r.exerciseId).toList(), [
        'barbell-back-squat',
        'barbell-bench-press',
        'barbell-row',
        'pull-up',
      ]);

      // Warm-up stands alone; bench→row→pull-up chained by two links
      // forms one superset group of three.
      expect(rows[0].supersetGroup, isNull);
      expect(rows[0].isWarmup, isTrue);
      expect(rows[1].supersetGroup, isNotNull);
      expect(rows[2].supersetGroup, rows[1].supersetGroup);
      expect(rows[3].supersetGroup, rows[1].supersetGroup);

      expect(rows[1].targetWeight, 60);
      expect(rows[1].targetSets, 3);
      expect(rows[1].targetReps, 8);
      expect(rows[1].restSeconds, inheritRestSeconds); // no override yet
    });

    test('re-save replaces children without duplicates', () async {
      final id = await repo.saveRoutine(name: 'A', entries: [
        draft('barbell-bench-press'),
        draft('barbell-row'),
      ]);
      await repo.saveRoutine(id: id, name: 'A Renamed', entries: [
        draft('barbell-bench-press', sets: 5),
        draft('barbell-row'),
        draft('pull-up'),
      ]);

      final routine =
          await (db.routines.select()..where((r) => r.id.equals(id)))
              .getSingle();
      expect(routine.name, 'A Renamed');

      final rows = await (db.routineExercises.select()
            ..where((e) => e.routineId.equals(id)))
          .get();
      expect(rows, hasLength(3)); // replaced, not appended
      expect(rows.every((r) => r.deletedAt == null), isTrue);
    });

    test('deleteRoutine tombstones the routine and its children', () async {
      final id = await repo.saveRoutine(name: 'Gone', entries: [
        draft('barbell-bench-press'),
        draft('barbell-row'),
      ]);
      await repo.deleteRoutine(id);

      final routine =
          await (db.routines.select()..where((r) => r.id.equals(id)))
              .getSingle();
      expect(routine.deletedAt, isNotNull);

      final children = await (db.routineExercises.select()
            ..where((e) => e.routineId.equals(id)))
          .get();
      expect(children.every((c) => c.deletedAt != null), isTrue);
    });
  });

  group('routinesProvider', () {
    test('aggregates counts and reacts to changes', () async {
      // Riverpod 3 pauses stream subscriptions with zero listeners, so a
      // bare `.future` read never resolves — listen while asserting.
      final emissions = <List<RoutineCard>>[];
      final sub = container.listen(routinesProvider, (_, next) {
        final cards = next.value;
        if (cards != null) emissions.add(cards);
      });
      addTearDown(sub.close);

      await repo.saveRoutine(name: 'A', entries: [
        draft('barbell-bench-press'),
        draft('barbell-row'),
      ]);
      await pumpEventQueue();
      expect(emissions, isNotEmpty);
      expect(emissions.last, hasLength(1));
      expect(emissions.last.single.exerciseCount, 2);
      expect(emissions.last.single.targetSetCount, 6); // 3 + 3 defaults

      await repo.saveRoutine(name: 'B', entries: [draft('pull-up')]);
      await pumpEventQueue();
      expect(emissions.last, hasLength(2));

      final doomed = emissions.last.firstWhere((c) => c.routine.name == 'A');
      await repo.deleteRoutine(doomed.routine.id);
      await pumpEventQueue();
      expect(emissions.last.map((c) => c.routine.name), ['B']);
    });
  });

  group('startWorkout from routine', () {
    test('seeds planned sets with targets and superset groups', () async {
      final id = await repo.saveRoutine(name: 'Legs', entries: [
        draft('barbell-back-squat',
            sets: 3, reps: 5, weight: 100, linkNext: true),
        draft('leg-press', sets: 2, reps: 10, weight: 140),
      ]);

      await session().startWorkout(routineId: id);
      final s = await readSession();

      expect(s, isNotNull);
      expect(s!.workout.routineId, id);
      expect(s.workout.status, 'active');
      expect(s.exercises.map((e) => e.id),
          ['barbell-back-squat', 'leg-press']);
      expect(s.sets, hasLength(5)); // 3 + 2 planned
      expect(s.sets.every((x) => !x.isCompleted), isTrue);
      expect(s.completedSetCount, 0);
      expect(s.volumeKg, 0); // nothing completed yet

      final squat = s.setsFor('barbell-back-squat');
      expect(squat, hasLength(3));
      expect(squat.first.weightKg, 100);
      expect(squat.first.reps, 5);
      expect(squat.first.setType, 'working');

      // Link spans both exercises.
      final press = s.setsFor('leg-press');
      expect(squat.first.supersetGroup, isNotNull);
      expect(press.first.supersetGroup, squat.first.supersetGroup);
      expect(press.first.weightKg, 140);
    });

    test('completing a planned set stamps loggedAt and counts volume',
        () async {
      final id = await repo.saveRoutine(name: 'Legs', entries: [
        draft('barbell-back-squat', sets: 3, reps: 5, weight: 100),
      ]);
      await session().startWorkout(routineId: id);
      final planned = (await readSession())!.sets.first;

      await session().updateSet(planned.id, complete: true, weightKg: 95);

      final s = await readSession();
      expect(s!.completedSetCount, 1);
      // Working set: 95 × 5 = 475 kg toward volume.
      expect(s.volumeKg, closeTo(475, 0.001));

      final row = await (db.workoutSets.select()
            ..where((x) => x.id.equals(planned.id)))
          .getSingle();
      expect(row.isCompleted, isTrue);
      expect(row.weightKg, 95);
      expect(row.loggedAt, isNotNull);
      expect(row.reps, 5); // untouched
    });

    test('warm-up routine sets seed as warmup type', () async {
      final id = await repo.saveRoutine(name: 'Warm', entries: [
        draft('face-pull', sets: 2, reps: 15, warmup: true),
      ]);
      await session().startWorkout(routineId: id);
      final s = await readSession();
      expect(s!.sets, hasLength(2));
      expect(s.sets.every((x) => x.setType == 'warmup'), isTrue);
      // Warm-up sets don't count toward working volume even when done.
      await session().updateSet(s.sets.first.id, complete: true);
      expect((await readSession())!.volumeKg, 0);
    });

    test('per-type counts seed warmup → working → drop → failure in order',
        () async {
      final id = await repo.saveRoutine(name: 'Types', entries: [
        draft('barbell-bench-press',
            sets: 7, reps: 8, warmupSets: 2, dropSets: 1, failureSets: 1),
      ]);
      await session().startWorkout(routineId: id);
      final s = await readSession();

      // 2 + 3 working + 1 + 1 = 7 total, in that order.
      expect(s!.sets.map((x) => x.setType).toList(), [
        'warmup',
        'warmup',
        'working',
        'working',
        'working',
        'drop',
        'failure',
      ]);

      // Warm-up excluded, drop/failure included in volume when completed.
      for (final x in s.sets) {
        await session().updateSet(x.id, complete: true, weightKg: 60);
      }
      final done = (await readSession())!;
      expect(done.volumeKg, closeTo(60 * 8 * 5, 0.001)); // working+drop+fail
    });

    test('an explicit rest override is persisted; default stays inherit',
        () async {
      final id = await repo.saveRoutine(name: 'Rest', entries: [
        draft('barbell-bench-press', restSeconds: 150),
        draft('barbell-row'),
      ]);
      final rows = await (db.routineExercises.select()
            ..where((e) => e.routineId.equals(id))
            ..orderBy([(e) => OrderingTerm.asc(e.orderIndex)]))
          .get();
      expect(rows[0].restSeconds, 150);
      expect(rows[1].restSeconds, inheritRestSeconds);
      // Legacy flag mirrors "plans at least one warm-up set".
      expect(rows[0].isWarmup, isFalse);
    });

    test('guard: a second startWorkout while active is a no-op', () async {
      final id = await repo.saveRoutine(name: 'A', entries: [
        draft('pull-up'),
      ]);
      await session().startWorkout(routineId: id);
      await session().startWorkout(routineId: id); // ignored

      final rows = await (db.workouts.select()
            ..where((w) => w.status.equals('active')))
          .get();
      expect(rows, hasLength(1));
      final sets = await (db.workoutSets.select()
            ..where((s) => s.workoutId.equals(rows.single.id)))
          .get();
      expect(sets, hasLength(3)); // not doubled
    });
  });
}
