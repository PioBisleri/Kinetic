import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/export/export_service.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() async => db.close());

  final t = DateTime(2026, 9, 20, 18, 5, 30);

  Future<({List<Exercise> exercises, List<ExerciseMuscleMapData> map,
      List<Routine> routines, List<RoutineExercise> slots,
      List<Workout> workouts, List<WorkoutSet> sets})> seedFixture() async {
    await db.exercises.insertOnConflictUpdate(ExercisesCompanion.insert(
      id: 'barbell-bench-press',
      name: 'Barbell Bench Press',
      mechanics: 'compound',
      primaryMuscleId: 'chest',
      updatedAt: t,
    ));
    await db.exerciseMuscleMap.insertOnConflictUpdate(
        ExerciseMuscleMapCompanion.insert(
      exerciseId: 'barbell-bench-press',
      muscleId: 'chest',
      role: const Value('primary'),
    ));
    await db.routines.insertOnConflictUpdate(RoutinesCompanion.insert(
      id: 'r1',
      userId: 'local',
      name: 'Push Day',
      description: const Value('bench + ohp'),
      updatedAt: t,
    ));
    await db.routineExercises.insertOnConflictUpdate(
        RoutineExercisesCompanion.insert(
      id: 're1',
      routineId: 'r1',
      exerciseId: 'barbell-bench-press',
      orderIndex: 0,
      targetWeight: const Value(60),
      updatedAt: t,
    ));
    await db.workouts.insertOnConflictUpdate(WorkoutsCompanion.insert(
      id: 'w1',
      userId: 'local',
      startedAt: t,
      status: const Value('completed'),
      notes: const Value('felt strong, "paused" reps'),
      updatedAt: t,
    ));
    await db.workoutSets.insertOnConflictUpdate(WorkoutSetsCompanion.insert(
      id: 's1',
      workoutId: 'w1',
      exerciseId: 'barbell-bench-press',
      orderIndex: 0,
      weightKg: const Value(70),
      reps: const Value(5),
      isCompleted: const Value(true),
      loggedAt: Value(t),
      updatedAt: t,
    ));
    await db.workoutSets.insertOnConflictUpdate(WorkoutSetsCompanion.insert(
      id: 's2',
      workoutId: 'w1',
      exerciseId: 'barbell-bench-press',
      orderIndex: 1,
      reps: const Value(5),
      isCompleted: const Value(false),
      updatedAt: t,
    ));

    return (
      exercises: await db.exercises.select().get(),
      map: await db.exerciseMuscleMap.select().get(),
      routines: await db.routines.select().get(),
      slots: await db.routineExercises.select().get(),
      workouts: await db.workouts.select().get(),
      sets: await db.workoutSets.select().get(),
    );
  }

  group('buildBackupJson', () {
    test('nests children under their parents with ISO timestamps', () async {
      final f = await seedFixture();
      final json = buildBackupJson(
        exportedAt: DateTime(2026, 9, 25, 12),
        profile: null,
        exercises: f.exercises,
        muscleMap: f.map,
        routines: f.routines,
        routineExercises: f.slots,
        workouts: f.workouts,
        sets: f.sets,
      );

      expect(json, contains('"app": "kinetic"'));
      expect(json, contains('"exportedAt": "2026-09-25T12:00:00.000"'));
      // ISO strings, never drift's epoch-millis default.
      expect(json, contains('"updatedAt": "2026-09-20T18:05:30.000"'));
      expect(
        RegExp(r'"updatedAt": \d{10,}').hasMatch(json),
        isFalse,
        reason: 'timestamps must be ISO strings, not epoch millis',
      );
      // Nesting.
      expect(json, contains('"muscleMap"'));
      expect(json, contains('"entries"'));
      expect(json, contains('"sets"'));
      expect(json, contains('"targetWeight": 60.0'));
      expect(json, contains('"weightKg": 70.0'));
      expect(json, contains('"isCompleted": false'));
    });
  });

  group('buildSetsCsv', () {
    test('emits a header and one row per set, nulls as empty cells',
        () async {
      final f = await seedFixture();
      final csv = buildSetsCsv(f.sets, {
        for (final e in f.exercises) e.id: e.name,
      });
      final lines = csv.trimRight().split('\n');
      expect(lines.first, startsWith('date,logged_at,workout_id,exercise,'));
      expect(lines, hasLength(3)); // header + 2 sets
      expect(lines[1], contains('2026-09-20'));
      expect(lines[1], contains('Barbell Bench Press'));
      expect(lines[1], contains('70.0,5,'));
      // Planned set: empty weight/logged_at cells, completed=false.
      expect(lines[2], contains(',false,'));
      expect(lines[2], isNot(contains('null')));
    });

    test('quotes fields containing commas and doubles embedded quotes',
        () async {
      final row = WorkoutSet(
        id: 's1',
        workoutId: 'w1',
        exerciseId: 'cus_x',
        orderIndex: 0,
        setType: 'working',
        supersetGroup: null,
        weightKg: null,
        reps: 3,
        rpe: null,
        distanceM: null,
        durationSec: null,
        heartRate: null,
        isCompleted: true,
        loggedAt: t,
        notes: 'easy, then "grind",\nslow',
        updatedAt: t,
        syncedAt: null,
        deletedAt: null,
      );
      final csv = buildSetsCsv([row], {'cus_x': 'Cable, Fly'});
      expect(csv, contains('"Cable, Fly"'));
      expect(csv, contains('"easy, then ""grind"",\nslow"'));
    });
  });
}
