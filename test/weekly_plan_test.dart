import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/app.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/database/seed_service.dart';
import 'package:kinetic/core/settings/settings.dart';
import 'package:kinetic/features/routines/application/routine_repository.dart';
import 'package:kinetic/features/routines/weekly_plan_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const KineticApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Must be the LAST call in every test (see widget_test.dart).
  Future<void> endApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  /// Routines have no tab here — the plan lives behind the shell drawer.
  Future<void> openSchedule(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Schedule'));
    await tester.pumpAndSettle();
  }

  group('migration', () {
    test('v1 → v2 upgrade creates the weekly plan table', () async {
      // Force onCreate so the connection (and the full v2 schema) exists.
      await db.customSelect('SELECT 1').getSingle();

      // Reshape the database into v1: every table but the plan.
      await db.customStatement(
          'DROP TABLE ${db.weeklyPlans.actualTableName}');

      // Run the app's own onUpgrade branch — the exact code the phone
      // executes when Round 1's v1 install first opens Round 2.
      await db.migration.onUpgrade(Migrator(db), 1, 2);

      // The recreated table must be fully usable.
      await db.weeklyPlans.insertOnConflictUpdate(
        WeeklyPlansCompanion.insert(
          weekday: Value(1),
          routineId: Value('push-day'),
          updatedAt: DateTime.now(),
        ),
      );
      final row = await (db.weeklyPlans.select()
            ..where((w) => w.weekday.equals(1)))
          .getSingle();
      expect(row.routineId, 'push-day');
    });
  });

  testWidgets('plan a day, survive a cold start, then clear it',
      (tester) async {
    final routineId = await RoutineRepository(db)
        .saveRoutine(name: 'Push Day', entries: const []);

    Future<String?> dbMonday() async {
      final row = await (db.weeklyPlans.select()
            ..where((w) => w.weekday.equals(1)))
          .getSingle();
      return row.routineId;
    }

    await pumpApp(tester);
    await openSchedule(tester);

    expect(find.byType(WeeklyPlanPage), findsOneWidget);
    expect(find.text('Rest day'), findsNWidgets(7));

    // Assign Monday via the picker sheet.
    await tester.tap(find.byKey(const Key('plan-day-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('plan-assign-$routineId')));
    await tester.pumpAndSettle();

    expect(find.text('Push Day'), findsOneWidget);
    expect(find.text('Rest day'), findsNWidgets(6));
    expect(await dbMonday(), routineId);

    // Cold start: the assignment lives in SQLite, not widget state.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await pumpApp(tester);
    await openSchedule(tester);
    expect(find.text('Push Day'), findsOneWidget);

    // Clear Monday back to a rest day.
    await tester.tap(find.byKey(const Key('plan-day-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('plan-clear')));
    await tester.pumpAndSettle();

    expect(find.text('Rest day'), findsNWidgets(7));
    expect(find.text('Push Day'), findsNothing);
    expect(await dbMonday(), isNull);

    await endApp(tester);
  });

  testWidgets('empty weeks explain the picker instead of listing rows',
      (tester) async {
    await pumpApp(tester);
    await openSchedule(tester);
    expect(find.byType(WeeklyPlanPage), findsOneWidget);
    expect(find.textContaining('never'), findsOneWidget);

    // No routines created yet → the picker explains rather than listing.
    await tester.tap(find.byKey(const Key('plan-day-4')));
    await tester.pumpAndSettle();
    expect(find.textContaining('No routines yet'), findsOneWidget);
    expect(find.byKey(const Key('plan-clear')), findsNothing);

    await endApp(tester);
  });
}
