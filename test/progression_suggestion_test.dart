import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/database/seed_service.dart';
import 'package:kinetic/core/settings/settings.dart';
import 'package:kinetic/core/utils/weight_units.dart';
import 'package:kinetic/features/workout/application/suggestion_provider.dart';
import 'package:kinetic/features/workout/domain/suggestion_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Round 6: the suggestion engine's `incrementKg` plumbing — unit default
/// when no override exists, the exercise's `progressionIncrementKg` when
/// one does. The engine itself is covered by suggestion_engine_test; this
/// covers the provider glue between the row and the engine.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late SharedPreferences prefs;

  const exerciseId = 'barbell-bench-press';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await SeedService(db).ensureSeeded();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() => db.close());

  ProviderContainer makeContainer() {
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  /// One prior session: 100 kg × 10 — repped out, so the free-workout
  /// path suggests progress by exactly one increment.
  Future<void> seedHistory() async {
    final t = DateTime.now().toUtc();
    await db.workouts.insertOnConflictUpdate(WorkoutsCompanion.insert(
      id: 'w_prog',
      userId: 'local',
      startedAt: t,
      status: const Value('completed'),
      updatedAt: t,
    ));
    await db.workoutSets.insertOnConflictUpdate(WorkoutSetsCompanion.insert(
      id: 's_prog',
      workoutId: 'w_prog',
      exerciseId: exerciseId,
      orderIndex: 0,
      weightKg: const Value(100),
      reps: const Value(10),
      isCompleted: const Value(true),
      loggedAt: Value(t),
      updatedAt: t,
    ));
  }

  Future<Suggestion?> readSuggestion(ProviderContainer container) {
    final provider = exerciseSuggestionProvider(exerciseId);
    container.listen(provider, (_, _) {});
    return container.read(provider.future);
  }

  test('no override → unit default step (2.5 kg)', () async {
    await seedHistory();
    final s = await readSuggestion(makeContainer());

    expect(s, isNotNull);
    expect(s!.incrementKg, stepKg(UnitSystem.kg));
    expect(s.action, SuggestionAction.progress); // 10/10 reps
    expect(s.weightKg, 102.5); // 100 + 2.5
  });

  test('a per-exercise override drives the step', () async {
    await seedHistory();
    await (db.update(db.exercises)
          ..where((e) => e.id.equals(exerciseId)))
        .write(const ExercisesCompanion(progressionIncrementKg: Value(1.25)));

    final s = await readSuggestion(makeContainer());

    expect(s, isNotNull);
    expect(s!.incrementKg, 1.25);
    expect(s.weightKg, 101.25); // snap(100 + 1.25, 1.25)
    expect(s.action, SuggestionAction.progress);
  });

  test('round-trips through the exercise row back to inherit', () async {
    await seedHistory();
    await (db.update(db.exercises)
          ..where((e) => e.id.equals(exerciseId)))
        .write(const ExercisesCompanion(progressionIncrementKg: Value(1.25)));
    // Simulate the editor's "back to Default" save.
    await (db.update(db.exercises)
          ..where((e) => e.id.equals(exerciseId)))
        .write(const ExercisesCompanion(progressionIncrementKg: Value(null)));

    final s = await readSuggestion(makeContainer());

    expect(s, isNotNull);
    expect(s!.incrementKg, stepKg(UnitSystem.kg));
    expect(s.weightKg, 102.5);
  });
}
