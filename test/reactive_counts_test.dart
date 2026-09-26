import 'dart:async';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/database/seed_service.dart';
import 'package:kinetic/features/routines/exercise_detail_page.dart'
    show exerciseUsageProvider;

/// Regression tests for the `readsFrom` fixes: custom SELECTs drift can't
/// parse only re-emit their streams when the tables they read are declared.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await SeedService(db).ensureSeeded();
  });

  tearDown(() => db.close());

  /// Completes with the first emission of [stream] equal to [expected].
  /// Every new listener first receives the current value, then the stream
  /// re-emits after each covered write.
  Future<int> awaitEmission(Stream<int> stream, int expected) {
    final done = Completer<int>();
    final sub = stream.listen((value) {
      if (!done.isCompleted && value == expected) done.complete(value);
    });
    done.future.whenComplete(sub.cancel);
    return done.future.timeout(const Duration(seconds: 3));
  }

  test('exerciseCount re-emits the new total when an exercise is inserted',
      () async {
    final before = await db.exerciseCountOnce();
    final next = awaitEmission(db.exerciseCount(), before + 1);

    await db.into(db.exercises).insert(
          ExercisesCompanion.insert(
            id: 'cus_counter_probe',
            name: 'Counter Probe',
            mechanics: 'isolation',
            primaryMuscleId: 'chest',
            isCustom: const Value(true),
            ownerId: const Value('local'),
            updatedAt: DateTime.now().toUtc(),
          ),
        );

    expect(await next, before + 1);
  });

  test('exerciseUsage re-emits when a set is logged for the exercise',
      () async {
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    const exerciseId = 'barbell-bench-press';
    final provider = exerciseUsageProvider(exerciseId);
    container.listen(provider, (_, _) {});
    expect(await container.read(provider.future), 0);

    final done = Completer<int>();
    container.listen(provider, (_, next) {
      final value = next.value;
      if (!done.isCompleted && value == 1) done.complete(value);
    });

    final now = DateTime.now().toUtc();
    await db.into(db.workouts).insert(
          WorkoutsCompanion.insert(
            id: 'w_count_probe',
            userId: 'local',
            startedAt: now,
            updatedAt: now,
          ),
        );
    await db.into(db.workoutSets).insert(
          WorkoutSetsCompanion.insert(
            id: 's_count_probe',
            workoutId: 'w_count_probe',
            exerciseId: exerciseId,
            orderIndex: 0,
            isCompleted: const Value(true),
            loggedAt: Value(now),
            updatedAt: now,
          ),
        );

    expect(await done.future.timeout(const Duration(seconds: 3)), 1);
  });
}
