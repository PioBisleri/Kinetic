import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/database/seed_service.dart';
import 'package:kinetic/core/utils/day_key.dart';
import 'package:kinetic/features/history/domain/day_history.dart';
import 'package:kinetic/features/history/history_providers.dart';
import 'package:kinetic/features/workout/application/workout_session_notifier.dart';

/// Round 10 — History data layer: kcal math (golden values, lockstep
/// with the live notification), day bucketing incl. the midnight-spanning
/// session, weigh-in fallback, and the empty-day record.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // rootBundle for seeding
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await SeedService(db).ensureSeeded();
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    await container.read(workoutSessionProvider.future);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<String> anyExerciseId() async {
    final rows = await db.exercises.select().get();
    return rows.first.id;
  }

  /// A finished workout: [startedAt] local, one completed working set.
  Future<void> seedWorkout({
    required String id,
    required DateTime startedAt,
    int durationSec = 3600,
    bool withCardio = false,
  }) async {
    final exerciseId = await anyExerciseId();
    final now = DateTime.now();
    await db.workouts.insertOnConflictUpdate(WorkoutsCompanion.insert(
      id: id,
      userId: 'local',
      startedAt: startedAt,
      status: const Value('completed'),
      endedAt: Value(startedAt.add(Duration(seconds: durationSec))),
      durationSec: Value(durationSec),
      totalVolume: const Value(300),
      updatedAt: now,
    ));
    await db.workoutSets.insertOnConflictUpdate(WorkoutSetsCompanion.insert(
      id: '$id-set',
      workoutId: id,
      exerciseId: exerciseId,
      orderIndex: 0,
      setType: const Value('working'),
      weightKg: const Value(60),
      reps: const Value(5),
      isCompleted: const Value(true),
      loggedAt: Value(startedAt),
      updatedAt: now,
    ));
    if (withCardio) {
      await db.workoutSets.insertOnConflictUpdate(WorkoutSetsCompanion.insert(
        id: '$id-cardio',
        workoutId: id,
        exerciseId: exerciseId,
        orderIndex: 1,
        setType: const Value('cardio'),
        durationSec: const Value(600),
        isCompleted: const Value(true),
        loggedAt: Value(startedAt),
        updatedAt: now,
      ));
    }
  }

  group('kcal math (lockstep with KineticLiveService)', () {
    test('walkingKcal: 10k steps at 80 kg ≈ 631.8 kcal', () {
      expect(walkingKcal(10000, 80), closeTo(631.5, 0.1));
      expect(walkingKcal(5000, 80), closeTo(315.8, 0.1));
      expect(walkingKcal(0, 80), 0);
    });

    test('workoutBurnKcal: MET 4.5 — 1 h at 80 kg = 360 kcal', () {
      expect(workoutBurnKcal(3600, 80), closeTo(360, 0.001));
      expect(workoutBurnKcal(1800, 75), closeTo(168.75, 0.001));
      expect(workoutBurnKcal(0, 80), 0);
    });
  });

  test('empty day: all fields null/empty, isEmpty true', () async {
    final h =
        await container.read(dayHistoryProvider('2000-01-01').future);
    expect(h.isEmpty, isTrue);
    expect(h.weightKg, isNull);
    expect(h.prevWeightKg, isNull);
    expect(h.steps, isNull);
    expect(h.waterMl, isNull);
    expect(h.foodLogs, isEmpty);
    expect(h.workouts, isEmpty);
    expect(h.totals.kcal, 0);
    expect(h.walkingBurn, isNull);
    expect(h.totalBurned, isNull);
  });

  test('today: metrics, food, session, sets and burn all aggregate',
      () async {
    final today = dayKey(DateTime.now());
    final now = DateTime.now();
    await db.bodyMetrics.insertOnConflictUpdate(BodyMetricsCompanion.insert(
      id: today,
      steps: const Value(5000),
      waterMl: const Value(1200),
      weightKg: const Value(80),
      updatedAt: now,
    ));
    await db.foodLogs.insertOnConflictUpdate(FoodLogsCompanion.insert(
      id: 'log-1',
      dayKey: today,
      name: 'Rice bowl',
      kcal: 300,
      proteinG: 12,
      carbsG: 50,
      fatG: 4,
      loggedAt: now,
      updatedAt: now,
    ));
    await seedWorkout(id: 'w-1', startedAt: now, withCardio: true);

    final h = await container.read(dayHistoryProvider(today).future);
    expect(h.isEmpty, isFalse);
    expect(h.steps, 5000);
    expect(h.waterMl, 1200);
    expect(h.weightKg, 80);
    expect(h.foodLogs, hasLength(1));
    expect(h.totals.kcal, 300);
    expect(h.workouts, hasLength(1));
    expect(h.workouts.first.setCount, 2); // completed sets incl. cardio (house semantic)
    expect(h.workouts.first.cardioSec, 600);
    expect(h.walkingBurn, closeTo(315.8, 0.1));
    expect(h.workouts.first.kcalBurn, closeTo(360, 0.001));
    expect(h.totalBurned, closeTo(315.8 + 360, 0.2));
    expect(h.netKcal, closeTo(300 - (315.8 + 360), 0.2));
  });

  test('midnight-spanning workout buckets to its start day', () async {
    final today = dayKey(DateTime.now());
    final yesterdayDate = DateTime.now().subtract(const Duration(days: 1));
    final yesterday = dayKey(yesterdayDate);
    // Started 23:30 yesterday, ran an hour into today.
    final started = DateTime(
        yesterdayDate.year, yesterdayDate.month, yesterdayDate.day, 23, 30);
    await seedWorkout(id: 'w-span', startedAt: started);

    final y = await container.read(dayHistoryProvider(yesterday).future);
    final t = await container.read(dayHistoryProvider(today).future);
    expect(y.workouts.map((w) => w.workout.id), contains('w-span'));
    expect(t.workouts.map((w) => w.workout.id), isNot(contains('w-span')));
  });

  test('weigh-in fallback: prior day feeds burn, delta carries prev',
      () async {
    final today = dayKey(DateTime.now());
    final yDate = DateTime.now().subtract(const Duration(days: 1));
    final yesterday = dayKey(yDate);
    final now = DateTime.now();
    // Yesterday: weigh-in only.
    await db.bodyMetrics.insertOnConflictUpdate(BodyMetricsCompanion.insert(
      id: yesterday,
      weightKg: const Value(79.5),
      updatedAt: now,
    ));
    // Today: steps only, no weigh-in.
    await db.bodyMetrics.insertOnConflictUpdate(BodyMetricsCompanion.insert(
      id: today,
      steps: const Value(2000),
      updatedAt: now,
    ));

    final h = await container.read(dayHistoryProvider(today).future);
    expect(h.weightKg, isNull);
    expect(h.prevWeightKg, 79.5);
    expect(h.prevWeightDay, yesterday);
    expect(h.burnWeightKg, 79.5);
    expect(h.walkingBurn, isNotNull); // steps + fallback weight
    expect(h.walkingBurn, closeTo(79.5 * 2000 * 0.000762 * 1.036, 0.1));
  });

  test('weekBodyMetrics: window rows oldest-first, gaps stay missing',
      () async {
    final today = DateTime.now();
    String keyOf(int daysAgo) => dayKey(today.subtract(Duration(days: daysAgo)));
    for (final daysAgo in [0, 2, 5]) {
      await db.bodyMetrics
          .insertOnConflictUpdate(BodyMetricsCompanion.insert(
        id: keyOf(daysAgo),
        steps: Value(1000 * (daysAgo + 1)),
        updatedAt: DateTime.now(),
      ));
    }

    final rows = await container.read(weekBodyMetricsProvider(keyOf(0)).future);
    expect(rows, hasLength(3));
    expect(rows.first.id, keyOf(5)); // oldest first
    expect(rows.last.id, keyOf(0)); // selected day last
    expect(rows.map((r) => r.id), isNot(contains(keyOf(6)))); // outside window
  });
}
