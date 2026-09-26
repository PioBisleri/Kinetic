import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show AsyncProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/database/seed_service.dart';
import 'package:kinetic/features/analytics/application/analytics_providers.dart';
import 'package:kinetic/features/home/application/home_providers.dart';
import 'package:kinetic/features/routines/application/routine_repository.dart';
import 'package:kinetic/features/workout/application/workout_session_notifier.dart';

/// Repro for "workouts started from the Routines tab never reach
/// Analytics". The Routines tab and the Home button share one code path
/// (`startWorkout(routineId:)` → rollups → `finishWorkout`), so this test
/// drives the routine flow end-to-end and asserts the numbers Analytics
/// and Home actually read.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // rootBundle for seeding
  late AppDatabase db;
  late ProviderContainer container;

  WorkoutSessionNotifier notifier() =>
      container.read(workoutSessionProvider.notifier);

  Future<WorkoutSession?> read() =>
      container.read(workoutSessionProvider.future);

  /// Riverpod 3 won't start a StreamProvider without a listener, so listen
  /// first, await the first emission, then unsubscribe.
  Future<T> first<T>(AsyncProviderListenable<T> provider) async {
    final sub = container.listen(provider, (_, _) {});
    final value = await container.read(provider.future);
    sub.close();
    return value;
  }

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await SeedService(db).ensureSeeded();
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    await read();
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<String> seedRoutine() => RoutineRepository(db).saveRoutine(
        name: 'Push Day',
        entries: const [
          RoutineDraft(
              exerciseId: 'barbell-bench-press',
              targetSets: 2,
              targetReps: 5,
              targetWeight: 60),
          RoutineDraft(
              exerciseId: 'barbell-row', targetSets: 1, targetReps: 8),
        ],
      );

  test('routine workout flows into workout stats, history and rollups',
      () async {
    final routineId = await seedRoutine();
    await notifier().startWorkout(routineId: routineId);
    var session = await read();

    // Planned sets are seeded UNCOMPLETED — completing them is what puts
    // them into the rollups.
    expect(session!.sets, hasLength(3));
    expect(session.completedSetCount, 0);

    for (final s in session.sets) {
      await notifier().updateSet(s.id, complete: true);
    }
    session = await read();
    expect(session!.completedSetCount, 3);

    await notifier().finishWorkout();

    // 1. The workout row Analytics counts.
    final workouts = await db.select(db.workouts).get();
    expect(workouts, hasLength(1));
    expect(workouts.single.status, 'completed');
    expect(workouts.single.routineId, routineId);
    // 60×5×2 bench + 0×8 row (no target weight) — row only counts when
    // it has a weight.
    expect(workouts.single.totalVolume, closeTo(600, 0.001));

    // 2. ExerciseHistory rows (strength chart, "All" list, progress cards).
    final history = await db.select(db.exerciseHistory).get();
    expect(history.map((h) => h.exerciseId),
        contains('barbell-bench-press'));

    // 3. MuscleVolumeDaily rows (heat map, grade board, volume).
    final muscles = await db.select(db.muscleVolumeDaily).get();
    expect(muscles, isNotEmpty);
    expect(muscles.map((m) => m.muscleId), contains('chest'));

    // 4. What the Analytics stats card reads.
    final stats = await first(workoutStatsProvider(12));
    expect(stats.count, 1);

    // 5. What Home's Recent workouts list reads.
    final recent = await first(recentWorkoutsProvider);
    expect(recent, hasLength(1));
    expect(recent.single.title, 'Push Day');
    expect(recent.single.setCount, 3);
    expect(recent.single.workout.totalVolume, closeTo(600, 0.001));
  });

  test('finishing with untouched planned sets records a 0-set workout',
      () async {
    // The failure mode behind "history not saved": planned sets are
    // seeded uncompleted, and only completed sets enter the rollups —
    // so a finish-without-completing leaves no trace in Analytics.
    final routineId = await seedRoutine();
    await notifier().startWorkout(routineId: routineId);
    await notifier().finishWorkout();

    final stats = await first(workoutStatsProvider(12));
    expect(stats.count, 1); // the workout row exists…
    expect(await db.select(db.exerciseHistory).get(), isEmpty); // …but
    expect(await db.select(db.muscleVolumeDaily).get(), isEmpty); // …empty.

    final recent = await first(recentWorkoutsProvider);
    expect(recent.single.setCount, 0);
    expect(recent.single.workout.totalVolume, 0);
  });

  test('deleteCompletedWorkout removes the workout and rebuilds rollups',
      () async {
    final routineId = await seedRoutine();
    await notifier().startWorkout(routineId: routineId);
    final session = await read();
    for (final s in session!.sets) {
      await notifier().updateSet(s.id, complete: true);
    }
    await notifier().finishWorkout();
    final workoutId = (await db.select(db.workouts).get()).single.id;

    await deleteCompletedWorkout(db, workoutId);

    expect(await db.select(db.workouts).get(), isEmpty);
    expect(await db.select(db.workoutSets).get(), isEmpty);
    expect(await db.select(db.exerciseHistory).get(), isEmpty);
    expect(await db.select(db.muscleVolumeDaily).get(), isEmpty);

    final stats = await first(workoutStatsProvider(12));
    expect(stats.count, 0);
    final recent = await first(recentWorkoutsProvider);
    expect(recent, isEmpty);
  });
}
