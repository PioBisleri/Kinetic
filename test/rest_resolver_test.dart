import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/database/seed_service.dart';
import 'package:kinetic/core/settings/settings.dart';
import 'package:kinetic/features/routines/application/routine_repository.dart';
import 'package:kinetic/features/workout/application/rest_resolver.dart';
import 'package:kinetic/features/workout/application/workout_session_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late ProviderContainer container;
  late RoutineRepository repo;
  late SettingsState settings;

  const defaults = SettingsState(); // warm-up 60, working 90, failure 120

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await SeedService(db).ensureSeeded();
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    await container.read(workoutSessionProvider.future);
    repo = RoutineRepository(db);
    settings = defaults;
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  WorkoutSessionNotifier session() =>
      container.read(workoutSessionProvider.notifier);
  Future<WorkoutSession?> readSession() =>
      container.read(workoutSessionProvider.future);

  Future<int> resolve(String exerciseId, String setType,
      {WorkoutSession? session}) =>
      resolveRestSeconds(
        db: db,
        settings: settings,
        session: session,
        exerciseId: exerciseId,
        setType: setType,
      );

  group('per-type Settings fallback', () {
    test('warm-up / working / drop / failure pick their own defaults',
        () async {
      expect(await resolve('barbell-bench-press', 'warmup'), 60);
      expect(await resolve('barbell-bench-press', 'working'), 90);
      expect(await resolve('barbell-bench-press', 'drop'), 90);
      expect(await resolve('barbell-bench-press', 'failure'), 120);
    });

    test('edited Settings values are honoured', () async {
      settings = const SettingsState(
        restWarmupSec: 30,
        restWorkingSec: 180,
        restFailureSec: 240,
      );
      expect(await resolve('barbell-bench-press', 'warmup'), 30);
      expect(await resolve('barbell-bench-press', 'working'), 180);
      expect(await resolve('barbell-bench-press', 'drop'), 180);
      expect(await resolve('barbell-bench-press', 'failure'), 240);
    });
  });

  group('precedence', () {
    test('exercise override beats Settings but applies to every type',
        () async {
      await (db.exercises.update()
            ..where((e) => e.id.equals('barbell-bench-press')))
          .write(const ExercisesCompanion(restSeconds: Value(45)));

      expect(await resolve('barbell-bench-press', 'warmup'), 45);
      expect(await resolve('barbell-bench-press', 'failure'), 45);
      // An untouched exercise still falls through to the per-type default.
      expect(await resolve('barbell-row', 'warmup'), 60);
    });

    test('routine override beats the exercise override', () async {
      await (db.exercises.update()
            ..where((e) => e.id.equals('barbell-bench-press')))
          .write(const ExercisesCompanion(restSeconds: Value(45)));

      final routineId = await repo.saveRoutine(name: 'Push', entries: [
        RoutineDraft(
          exerciseId: 'barbell-bench-press',
          targetSets: 3,
          targetReps: 8,
          restSeconds: 150,
        ),
        const RoutineDraft(
          exerciseId: 'barbell-row',
          targetSets: 3,
          targetReps: 8,
        ),
      ]);
      await session().startWorkout(routineId: routineId);
      final s = await readSession();

      // Overridden entry — one rest for all of its set types.
      expect(await resolve('barbell-bench-press', 'warmup', session: s), 150);
      expect(await resolve('barbell-bench-press', 'failure', session: s), 150);

      // Sibling entry has no override → exercise (null) → Settings.
      expect(await resolve('barbell-row', 'working', session: s), 90);
    });

    test('routine entry on "Default rest" keeps falling through', () async {
      final routineId = await repo.saveRoutine(name: 'Pull', entries: [
        const RoutineDraft(
          exerciseId: 'barbell-row',
          targetSets: 3,
          targetReps: 8,
          restSeconds: inheritRestSeconds,
        ),
      ]);
      await session().startWorkout(routineId: routineId);
      final s = await readSession();

      expect(await resolve('barbell-row', 'warmup', session: s), 60);
      expect(await resolve('barbell-row', 'failure', session: s), 120);
    });

    test('an exercise added mid-session has no routine entry → Settings',
        () async {
      final routineId = await repo.saveRoutine(
          name: 'Legs',
          entries: [
            const RoutineDraft(
              exerciseId: 'leg-press',
              targetSets: 2,
              targetReps: 10,
              restSeconds: 200,
            ),
          ]);
      await session().startWorkout(routineId: routineId);
      await session().addExercise('pull-up'); // not in the routine
      final s = await readSession();

      expect(await resolve('leg-press', 'working', session: s), 200);
      expect(await resolve('pull-up', 'working', session: s), 90);
    });

    test('no active workout still resolves (free workout path)', () async {
      expect(await resolve('barbell-bench-press', 'warmup'), 60);
    });
  });
}
