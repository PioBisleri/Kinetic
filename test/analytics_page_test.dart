import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/app.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/database/seed_service.dart';
import 'package:kinetic/core/settings/settings.dart';
import 'package:kinetic/core/theme/app_theme.dart';
import 'package:kinetic/features/analytics/analytics_page.dart';
import 'package:kinetic/features/analytics/application/analytics_providers.dart';
import 'package:kinetic/features/analytics/application/rollup_service.dart';
import 'package:kinetic/features/analytics/domain/analytics_math.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Balance pairs come from the bundled seed, but `rootBundle` futures never
/// complete inside the FakeAsync `testWidgets` body (verified by probe) —
/// parse the file synchronously here instead. The real rootBundle provider
/// path is covered by muscle_window_test's plain-zone test.
List<BalancePairConfig> _loadSeedPairs() {
  final raw = File('assets/seed/muscle_groups.json').readAsStringSync();
  final json = jsonDecode(raw) as Map<String, dynamic>;
  return [
    for (final p in json['balance_pairs'] as List)
      BalancePairConfig.fromJson(p as Map<String, dynamic>),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late SharedPreferences prefs;
  var seq = 0;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await SeedService(db).ensureSeeded();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
          balancePairsProvider
              .overrideWith((_) => Future.value(_loadSeedPairs())),
        ],
        child: const KineticApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Analytics'));
    await tester.pumpAndSettle();
  }

  /// Must be the LAST call in every test (see widget_test.dart).
  Future<void> endApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  /// One finished workout on [day] with a single completed set + rollups.
  Future<void> seedWorkout(
    DateTime day, {
    String exerciseId = 'barbell-bench-press',
    double weightKg = 60,
    int reps = 5,
  }) async {
    final id = 'w-${seq++}';
    await db.workouts.insertOnConflictUpdate(WorkoutsCompanion.insert(
      id: id,
      userId: 'local',
      startedAt: day,
      updatedAt: day,
      status: const Value('completed'),
      endedAt: Value(day.add(const Duration(hours: 1))),
      durationSec: const Value(3600),
      totalVolume: const Value(0),
    ));
    await db.workoutSets.insertOnConflictUpdate(WorkoutSetsCompanion.insert(
      id: 's-$id',
      workoutId: id,
      exerciseId: exerciseId,
      orderIndex: 0,
      setType: const Value('working'),
      weightKg: Value(weightKg),
      reps: Value(reps),
      isCompleted: const Value(true),
      loggedAt: Value(day),
      updatedAt: day,
    ));
    await RollupService(db).recomputeDay(day);
  }

  testWidgets('empty state before any workout', (tester) async {
    await pumpApp(tester);

    expect(find.byKey(const Key('period-12')), findsOneWidget);
    expect(
      tester.widget<ChoiceChip>(find.byKey(const Key('period-12'))).selected,
      isTrue,
    );
    expect(find.textContaining('No finished workouts yet'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('stat-workouts'))).data,
      '0',
    );
    expect(find.byType(BarChart), findsNothing);
    expect(find.byType(LineChart), findsNothing);

    await endApp(tester);
  });

  testWidgets('renders stats, charts and calendar from real data',
      (tester) async {
    final today = dayOf(DateTime.now());
    await seedWorkout(addDays(today, -2), weightKg: 60, reps: 5); // 300 kg
    await seedWorkout(addDays(today, -1), weightKg: 65, reps: 5); // 325 kg

    await pumpApp(tester);

    expect(
      tester.widget<Text>(find.byKey(const Key('stat-workouts'))).data,
      '2',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('stat-volume'))).data,
      '625 kg',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('stat-streak'))).data,
      matches(RegExp(r'^\d+w$')),
    );
    expect(find.byType(BarChart), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget);
    expect(find.byKey(const Key('exercise-picker')), findsOneWidget);
    expect(find.text('Barbell Bench Press'), findsWidgets);

    // Yesterday's calendar cell is marked as trained (may need a scroll).
    final cellKey = ValueKey('cal-${addDays(today, -1).millisecondsSinceEpoch}');
    await tester.scrollUntilVisible(find.byKey(cellKey), 200);
    await tester.pumpAndSettle();
    final cell = tester.widget<Container>(find.byKey(cellKey));
    expect((cell.decoration! as BoxDecoration).color, AppColors.accent);

    await endApp(tester);
  });

  testWidgets('period chips switch the window', (tester) async {
    await seedWorkout(dayOf(DateTime.now()));
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('period-4')));
    await tester.pumpAndSettle();

    final container =
        ProviderScope.containerOf(tester.element(find.byType(AnalyticsPage)));
    expect(container.read(analyticsPeriodProvider), 4);
    expect(
      tester.widget<ChoiceChip>(find.byKey(const Key('period-4'))).selected,
      isTrue,
    );
    expect(find.byType(BarChart), findsOneWidget);

    await endApp(tester);
  });

  testWidgets('All chip widens the window to full history', (tester) async {
    final today = dayOf(DateTime.now());
    // A workout 8 weeks ago: inside 12W (default), outside 4W.
    final longAgo = addDays(today, -56);
    await seedWorkout(longAgo, weightKg: 100, reps: 5);
    await seedWorkout(addDays(today, -1), weightKg: 60, reps: 5);
    await pumpApp(tester);

    // Default 12W counts both…
    expect(
      tester.widget<Text>(find.byKey(const Key('stat-workouts'))).data,
      '2',
    );

    // …4W drops the old one…
    await tester.tap(find.byKey(const Key('period-4')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('stat-workouts'))).data,
      '1',
    );

    // …and All brings it back.
    await tester.tap(find.byKey(const Key('period-0')));
    await tester.pumpAndSettle();

    final container =
        ProviderScope.containerOf(tester.element(find.byType(AnalyticsPage)));
    expect(container.read(analyticsPeriodProvider), 0);
    expect(
      tester.widget<ChoiceChip>(find.byKey(const Key('period-0'))).selected,
      isTrue,
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('stat-workouts'))).data,
      '2',
    );
    // 56 days = 8 full weeks back → 9 weekly buckets (8 + this week).
    expect(find.byType(BarChart), findsOneWidget);
    final bars = tester.widget<BarChart>(find.byType(BarChart));
    expect(bars.data.barGroups, hasLength(9));

    await endApp(tester);
  });

  testWidgets('grade board, heat map and balance render from rollups',
      (tester) async {
    final today = dayOf(DateTime.now());
    // A finished workout gets us past the empty-state gate…
    await seedWorkout(addDays(today, -3));
    // …and explicit rollups make the balance maths deterministic
    // (recomputeDay above only touched its own day for chest).
    await db.muscleVolumeDaily.insertOnConflictUpdate(
      MuscleVolumeDailyCompanion.insert(
        userId: 'local',
        muscleId: 'chest',
        date: today,
        totalSets: const Value(20),
        volume: const Value(9000),
        bestE1Rm: const Value(90),
      ),
    );
    await db.muscleVolumeDaily.insertOnConflictUpdate(
      MuscleVolumeDailyCompanion.insert(
        userId: 'local',
        muscleId: 'lats',
        date: today,
        totalSets: const Value(4),
        volume: const Value(800),
        bestE1Rm: const Value(70),
      ),
    );

    await pumpApp(tester);

    // Grade board: every graded muscle gets a keyed cell (cardio excluded).
    await tester.scrollUntilVisible(find.byKey(const Key('grade-chest')), 200);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('grade-chest')), findsOneWidget);
    expect(find.byKey(const Key('grade-quads')), findsOneWidget);
    expect(find.byKey(const Key('grade-cardio')), findsNothing);
    expect(find.text('Muscle Grades'), findsOneWidget);

    // Body heat map: both views + legend.
    await tester.scrollUntilVisible(find.byKey(const Key('heat-front')), 200);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('heat-back')), findsOneWidget);
    expect(find.text('Body Heat Map'), findsOneWidget);
    expect(find.text('Fresh'), findsOneWidget);

    // Balance: chest (9000) towers over the back side (800).
    await tester.scrollUntilVisible(find.text('Chest vs Back'), 200);
    await tester.pumpAndSettle();
    expect(find.text('Chest vs Back'), findsOneWidget);
    expect(find.textContaining('undertrained'), findsWidgets);

    await endApp(tester);
  });
}
