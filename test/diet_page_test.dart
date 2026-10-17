import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/database/seed_service.dart';
import 'package:kinetic/core/settings/settings.dart';
import 'package:kinetic/core/utils/day_key.dart';
import 'package:kinetic/features/nutrition/diet_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Round 8 — the /diet page: today's macros, quick-add water, log tiles
/// and the food library, all straight over an in-memory drift.
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
    // The page stacks three cards plus two sections — taller than the
    // default 600 px test viewport, so widen it to reach everything.
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 2000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(home: DietPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> endPage(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('empty state: zero totals, no logs, empty-library hint',
      (tester) async {
    await pumpPage(tester);

    expect(find.text('Diet'), findsOneWidget);
    expect(find.text('Nothing logged yet.'), findsOneWidget);
    expect(
      find.textContaining('No foods yet'),
      findsOneWidget,
    );
    expect(find.text('+250'), findsOneWidget);
    expect(find.byKey(const Key('diet-water-segments')), findsOneWidget);
    expect(find.text('0 / 2500 ml'), findsOneWidget); // default water target

    await endPage(tester);
  });

  testWidgets('+250 water updates the day row and the total',
      (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('+250'));
    await tester.pumpAndSettle();

    final row = await db.bodyMetricOnce(dayKey(DateTime.now()));
    expect(row!.waterMl, 250);
    expect(row.syncedAt, isNull);
    expect(find.text('250 / 2500 ml'), findsOneWidget);
    // Undo snack must auto-dismiss (Flutter 3.38 persists snackbars with
    // an action by default — the Round 9.1 bug report).
    final snack = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snack.persist, isFalse);

    await endPage(tester);
  });

  testWidgets('library tile tap logs one serving; totals reflect it',
      (tester) async {
    final day = dayKey(DateTime.now());
    await db.foods.insertOnConflictUpdate(FoodsCompanion.insert(
      id: 'food-1',
      name: 'Whey',
      kcal: const Value(120),
      proteinG: const Value(25),
      carbsG: const Value(3),
      fatG: const Value(1.5),
      updatedAt: DateTime.now(),
    ));

    await pumpPage(tester);

    // The library row is rendered with its per-serving macros…
    expect(find.text('Whey'), findsOneWidget);

    // …and one tap logs one serving into today's list.
    await tester.tap(find.text('Whey'));
    await tester.pumpAndSettle();

    final logs = await (db.foodLogs.select()
          ..where((l) => l.dayKey.equals(day)))
        .get();
    expect(logs, hasLength(1));
    expect(logs.single.kcal, 120);
    expect(logs.single.proteinG, 25);
    expect(logs.single.name, 'Whey');
    expect(find.byKey(Key('diet-log-delete-${logs.single.id}')),
        findsOneWidget);

    await endPage(tester);
  });

  testWidgets('logged foods render with servings and a delete control',
      (tester) async {
    final day = dayKey(DateTime.now());
    await db.foodLogs.insertOnConflictUpdate(FoodLogsCompanion.insert(
      id: 'log-1',
      dayKey: day,
      name: 'Rice bowl',
      servings: const Value(1.5),
      kcal: 300,
      proteinG: 12,
      carbsG: 50,
      fatG: 4,
      loggedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    await pumpPage(tester);

    expect(find.text('Rice bowl'), findsOneWidget);
    expect(find.textContaining('1.5 servings'), findsOneWidget);
    expect(find.text('300 kcal'), findsOneWidget);

    // Delete → tombstone in the DB, row disappears from the list.
    await tester.tap(find.byKey(const Key('diet-log-delete-log-1')));
    await tester.pumpAndSettle();

    final log = await (db.foodLogs.select()
          ..where((l) => l.id.equals('log-1')))
        .getSingle();
    expect(log.deletedAt, isNotNull);
    expect(find.text('Rice bowl'), findsNothing);

    await endPage(tester);
  });

  testWidgets('steps card: today vs target, read-only', (tester) async {
    // Seed a metric day with steps only (no weigh-in, no water).
    await db.bodyMetrics.insertOnConflictUpdate(BodyMetricsCompanion.insert(
      id: dayKey(DateTime.now()),
      steps: const Value(4210),
      updatedAt: DateTime.now().toUtc(),
    ));

    await pumpPage(tester);

    expect(find.text('STEPS'), findsOneWidget);
    expect(find.text('4210 / 8000 steps'), findsOneWidget);
    expect(find.byKey(const Key('diet-steps-scale')), findsOneWidget);
    // There is no editor for steps — sensor-only by design.
    expect(find.textContaining('4210 steps'), findsNothing);

    await endPage(tester);
  });

  testWidgets('headers keep their add buttons readable at large text scale',
      (tester) async {
    final day = dayKey(DateTime.now());
    await db.bodyMetrics.insertOnConflictUpdate(BodyMetricsCompanion.insert(
      id: day,
      steps: const Value(1000),
      updatedAt: DateTime.now().toUtc(),
    ));

    // Big system font (the report from the field) — the old full
    // "Log food" button ate the row width; the icon-only button must not.
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpPage(tester);

    expect(find.byKey(const Key('diet-log-food')), findsOneWidget);
    expect(find.byKey(const Key('diet-new-food')), findsOneWidget);
    // The section titles render on a single line, not one letter per row.
    expect(find.text("Today's food", findRichText: true), findsOneWidget);
    expect(find.text('My foods', findRichText: true), findsOneWidget);

    await endPage(tester);
  });
}
