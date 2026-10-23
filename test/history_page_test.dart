import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/database/seed_service.dart';
import 'package:kinetic/core/settings/settings.dart';
import 'package:kinetic/core/utils/day_key.dart';
import 'package:kinetic/features/history/history_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Round 10 — the /history page: date selector, six sub-tabs and the
/// All-tab composite, straight over an in-memory drift.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late SharedPreferences prefs;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await SeedService(db).ensureSeeded();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() => db.close());

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 2000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(home: HistoryPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> endPage(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  /// One full day: metric (steps + water + weigh-in), a food log and a
  /// finished workout with a completed set.
  Future<void> seedToday() async {
    final today = dayKey(DateTime.now());
    final now = DateTime.now();
    final exercises = await db.exercises.select().get();
    final exerciseId = exercises.first.id;

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
    await db.workouts.insertOnConflictUpdate(WorkoutsCompanion.insert(
      id: 'w-1',
      userId: 'local',
      startedAt: now,
      status: const Value('completed'),
      endedAt: Value(now.add(const Duration(hours: 1))),
      durationSec: const Value(3600),
      totalVolume: const Value(300),
      updatedAt: now,
    ));
    await db.workoutSets.insertOnConflictUpdate(WorkoutSetsCompanion.insert(
      id: 'w-1-set',
      workoutId: 'w-1',
      exerciseId: exerciseId,
      orderIndex: 0,
      setType: const Value('working'),
      weightKg: const Value(60),
      reps: const Value(5),
      isCompleted: const Value(true),
      loggedAt: Value(now),
      updatedAt: now,
    ));
  }

  testWidgets('empty day: date bar, six tabs and the empty state',
      (tester) async {
    await pumpPage(tester);

    final today = dayKey(DateTime.now());
    expect(find.byKey(const Key('history-prev-day')), findsOneWidget);
    expect(find.byKey(const Key('history-date-picker')), findsOneWidget);
    expect(
      find.text(DateFormat('EEE, d MMM yyyy').format(DateTime.now())),
      findsOneWidget,
    );
    expect(find.byKey(Key('history-date-$today')), findsOneWidget);
    // No "Today" jump while already on today.
    expect(find.byKey(const Key('history-today-jump')), findsNothing);
    for (final tab in ['all', 'workouts', 'steps', 'food', 'water', 'burned']) {
      expect(find.byKey(Key('history-tab-$tab')), findsOneWidget);
    }
    expect(find.textContaining('Nothing recorded on'), findsOneWidget);

    await endPage(tester);
  });

  testWidgets('seeded day: All tab shows steps, burn, intake, weigh-in, workout',
      (tester) async {
    await seedToday();
    await pumpPage(tester);

    expect(find.text('STEPS'), findsOneWidget);
    expect(find.text('WATER'), findsOneWidget);
    expect(find.text('CALORIES BURNED'), findsOneWidget);
    expect(find.text('INTAKE & NET'), findsOneWidget);
    expect(find.text('WEIGH-IN'), findsOneWidget);
    expect(find.text('WORKOUTS'), findsOneWidget);
    expect(find.text('5000'), findsOneWidget); // steps headline
    expect(find.text('1200'), findsOneWidget); // water headline
    expect(find.text('80.0'), findsOneWidget); // weigh-in (kg default)
    expect(find.byKey(const Key('history-workout-card-w-1')), findsOneWidget);
    expect(find.textContaining('kcal walking'), findsOneWidget);

    await endPage(tester);
  });

  testWidgets('prev arrow moves a day, keeps the sub-tab, Today jumps back',
      (tester) async {
    await seedToday();
    await pumpPage(tester);

    // Switch to Food first — the tab must survive a date change.
    await tester.tap(find.byKey(const Key('history-tab-food')));
    await tester.pumpAndSettle();
    expect(find.text('MACROS'), findsOneWidget);

    await tester.tap(find.byKey(const Key('history-prev-day')));
    await tester.pumpAndSettle();

    final yesterday =
        DateTime.now().subtract(const Duration(days: 1));
    expect(
      find.text(DateFormat('EEE, d MMM yyyy').format(yesterday)),
      findsOneWidget,
    );
    expect(
      find.byKey(Key('history-date-${dayKey(yesterday)}')),
      findsOneWidget,
    );
    // Still on Food after the date jump.
    expect(find.text('MACROS'), findsOneWidget);

    // Jump back to today.
    expect(find.byKey(const Key('history-today-jump')), findsOneWidget);
    await tester.tap(find.byKey(const Key('history-today-jump')));
    await tester.pumpAndSettle();
    expect(
      find.text(DateFormat('EEE, d MMM yyyy').format(DateTime.now())),
      findsOneWidget,
    );
    expect(find.byKey(const Key('history-today-jump')), findsNothing);

    await endPage(tester);
  });

  testWidgets('Burned tab: breakdown rows and formula footnote',
      (tester) async {
    await seedToday();
    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('history-tab-burned')));
    await tester.pumpAndSettle();

    expect(find.text('Walking'), findsWidgets); // All tab caches aside
    expect(find.text('Total'), findsWidgets);
    // Burned-only caption (the All tab words it differently).
    expect(find.textContaining('intake target'), findsOneWidget);
    expect(
      find.textContaining('walking: bodyweight × km × 1.036'),
      findsWidgets,
    );

    await endPage(tester);
  });

  testWidgets('Food tab: logged entry with time, macros and kcal',
      (tester) async {
    await seedToday();
    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('history-tab-food')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('history-food-log-1')), findsOneWidget);
    expect(find.text('Rice bowl'), findsOneWidget);
    expect(find.text('300 kcal'), findsWidgets);
    expect(find.textContaining('P 12'), findsOneWidget);
    expect(find.text('/ 2500 kcal'), findsOneWidget); // intake headline

    await endPage(tester);
  });

  testWidgets('calendar picker opens and cancels cleanly', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('history-date-picker')));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsNothing);
    await endPage(tester);
  });
}
