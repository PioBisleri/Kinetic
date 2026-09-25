import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/database/seed_service.dart';
import 'package:kinetic/features/workout/application/workout_session_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // rootBundle for seeding
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await SeedService(db).ensureSeeded();
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    // Initialize the AsyncNotifier so methods can read state immediately.
    await container.read(workoutSessionProvider.future);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<WorkoutSession?> read() =>
      container.read(workoutSessionProvider.future);

  WorkoutSessionNotifier notifier() =>
      container.read(workoutSessionProvider.notifier);

  test('starts with no active workout', () async {
    expect(await read(), isNull);
  });

  test('full workout lifecycle: start → add → log → finish', () async {
    await notifier().startWorkout();
    var session = await read();
    expect(session, isNotNull);
    expect(session!.workout.status, 'active');

    await notifier().addExercise('barbell-bench-press');
    session = await read();
    // Appears even before its first set (setless overlay).
    expect(session!.exercises.single.id, 'barbell-bench-press');
    expect(session.sets, isEmpty);

    await notifier().logSet(
        exerciseId: 'barbell-bench-press', weightKg: 60, reps: 5);
    await notifier().logSet(
        exerciseId: 'barbell-bench-press',
        weightKg: 62.5,
        reps: 5,
        setType: 'warmup');

    session = await read();
    expect(session!.sets, hasLength(2));
    expect(session.completedSetCount, 2);
    // Warm-ups don't count; hard sets do: 60 × 5 = 300 kg.
    expect(session.volumeKg, closeTo(300, 0.001));

    await notifier().finishWorkout();
    expect(await read(), isNull);

    final rows = await db.select(db.workouts).get();
    expect(rows, hasLength(1));
    expect(rows.single.status, 'completed');
    expect(rows.single.totalVolume, closeTo(300, 0.001));
    expect(rows.single.endedAt, isNotNull);
    expect(rows.single.durationSec, isNotNull);

    // Sets survive for the analytics phase.
    final sets = await db.select(db.workoutSets).get();
    expect(sets, hasLength(2));
  });

  test('setless exercise removal clears sets too', () async {
    await notifier().startWorkout();
    await notifier().addExercise('barbell-back-squat');
    await notifier()
        .logSet(exerciseId: 'barbell-back-squat', weightKg: 100, reps: 3);

    await notifier().removeExercise('barbell-back-squat');
    final session = await read();
    expect(session!.exercises, isEmpty);
    expect(session.sets, isEmpty);
  });

  test('duplicate adds are ignored', () async {
    await notifier().startWorkout();
    await notifier().addExercise('pull-up');
    await notifier().addExercise('pull-up');
    final session = await read();
    expect(session!.exercises, hasLength(1));
  });

  test('superset linking assigns a shared group to both exercises', () async {
    await notifier().startWorkout();
    await notifier().addExercise('barbell-bench-press');
    await notifier().addExercise('barbell-row');
    await notifier()
        .logSet(exerciseId: 'barbell-bench-press', weightKg: 60, reps: 5);

    await notifier().supersetWithNext('barbell-bench-press');

    final session = await read();
    final benchGroup = session!.supersetGroupOf('barbell-bench-press');
    final rowGroup = session.supersetGroupOf('barbell-row');
    expect(benchGroup, isNotNull);
    expect(rowGroup, benchGroup);

    // Durable: existing sets carry the group.
    expect(session.sets.single.supersetGroup, benchGroup);

    // New sets of the partner inherit the group.
    await notifier()
        .logSet(exerciseId: 'barbell-row', weightKg: 50, reps: 8);
    final after = await read();
    expect(after!.sets.last.supersetGroup, benchGroup);
  });

  test('notes persist onto the workout row', () async {
    await notifier().startWorkout();
    await notifier().saveWorkoutNotes('Felt strong.');
    final rows = await db.select(db.workouts).get();
    expect(rows.single.notes, 'Felt strong.');
  });

  test('updateSet edits values and stamps updatedAt', () async {
    await notifier().startWorkout();
    await notifier().addExercise('leg-press');
    final set = await notifier()
        .logSet(exerciseId: 'leg-press', weightKg: 140, reps: 10);

    await notifier().updateSet(set.id, weightKg: 145, rpe: 8);

    final row = await (db.select(db.workoutSets)
          ..where((s) => s.id.equals(set.id)))
        .getSingle();
    expect(row.weightKg, 145);
    expect(row.rpe, 8);
    expect(row.reps, 10); // untouched
    expect(row.updatedAt, isNotNull);
  });

  test('deleteSet removes the row', () async {
    await notifier().startWorkout();
    await notifier().addExercise('plank');
    final set = await notifier()
        .logSet(exerciseId: 'plank', durationSec: 60);
    await notifier().deleteSet(set.id);
    final session = await read();
    expect(session!.sets, isEmpty);
  });
}
