import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/app.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/database/seed_service.dart';
import 'package:kinetic/core/settings/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Live-logger controls: the RPE / distance / duration steppers (they used
/// to be wired to empty callbacks) and the discard-workout overflow action.
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

  /// Must be the LAST call in every test: unmounts the tree so Drift
  /// streams and tickers wind down cleanly.
  Future<void> endApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  /// Starts a session, adds one exercise through the searchable sheet and
  /// opens the big-target set editor for it.
  Future<void> openNewSetSheet(
    WidgetTester tester, {
    required String search,
    required String exerciseName,
    required String exerciseId,
  }) async {
    await tester.tap(find.text('Start Workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-exercise-empty')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), search);
    await tester.pumpAndSettle();
    await tester.tap(find.text(exerciseName));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('add-set-$exerciseId')));
    await tester.pumpAndSettle();
  }

  Finder plus(String fieldKey) => find.byKey(Key('stepper-plus-$fieldKey'));
  Finder minus(String fieldKey) => find.byKey(Key('stepper-minus-$fieldKey'));

  String fieldText(WidgetTester tester, String fieldKey) =>
      tester.widget<TextField>(find.byKey(Key(fieldKey))).controller!.text;

  testWidgets('RPE stepper steps by 0.5 (it was a dead no-op)',
      (tester) async {
    await pumpApp(tester);
    await openNewSetSheet(
      tester,
      search: 'bench',
      exerciseName: 'Barbell Bench Press',
      exerciseId: 'barbell-bench-press',
    );

    const rpe = 'set-rpe-input';
    expect(find.byKey(const Key(rpe)), findsOneWidget);
    expect(fieldText(tester, rpe), isEmpty);

    // Empty → floors at the bottom of the 1–10 scale, then steps 0.5.
    await tester.tap(plus(rpe));
    await tester.pumpAndSettle();
    expect(fieldText(tester, rpe), '1');
    await tester.tap(plus(rpe));
    await tester.pumpAndSettle();
    expect(fieldText(tester, rpe), '1.5');
    await tester.tap(minus(rpe));
    await tester.pumpAndSettle();
    expect(fieldText(tester, rpe), '1');
    // Repeated minuses clamp at 1 instead of going negative.
    await tester.tap(minus(rpe));
    await tester.pumpAndSettle();
    expect(fieldText(tester, rpe), '1');

    // The stepped value is what gets saved.
    await tester.ensureVisible(find.byKey(const Key('set-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('set-save')));
    await tester.pumpAndSettle();
    expect(find.text('RPE 1.0'), findsOneWidget);
    await endApp(tester);
  });

  testWidgets('cardio steppers drive distance and duration', (tester) async {
    await pumpApp(tester);
    await openNewSetSheet(
      tester,
      search: 'treadmill',
      exerciseName: 'Treadmill Run',
      exerciseId: 'treadmill-run',
    );

    const distance = 'set-distance-input';
    const duration = 'set-duration-input';
    expect(find.byKey(const Key(distance)), findsOneWidget);
    expect(find.byKey(const Key(duration)), findsOneWidget);
    expect(find.byKey(const Key('set-weight-input')), findsNothing);

    // Distance steps 10 m per tap.
    await tester.tap(plus(distance));
    await tester.pumpAndSettle();
    expect(fieldText(tester, distance), '10');
    await tester.tap(plus(distance));
    await tester.pumpAndSettle();
    expect(fieldText(tester, distance), '20');
    await tester.tap(minus(distance));
    await tester.pumpAndSettle();
    expect(fieldText(tester, distance), '10');

    // Duration steps 1 min per tap, shown with one decimal.
    await tester.tap(plus(duration));
    await tester.pumpAndSettle();
    expect(fieldText(tester, duration), '1.0');
    await tester.tap(plus(duration));
    await tester.pumpAndSettle();
    expect(fieldText(tester, duration), '2.0');
    await tester.tap(minus(duration));
    await tester.pumpAndSettle();
    expect(fieldText(tester, duration), '1.0');

    // Save lands a cardio set row in the session.
    await tester.ensureVisible(find.byKey(const Key('set-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('set-save')));
    await tester.pumpAndSettle();
    expect(find.text('10 m'), findsOneWidget);
    expect(find.text('1.0 min'), findsOneWidget);
    await endApp(tester);
  });

  testWidgets(
      'discard via overflow menu asks for confirmation and hard-deletes '
      'the session', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Start Workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-exercise-empty')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'bench');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Barbell Bench Press'));
    await tester.pumpAndSettle();
    expect(find.text('Finish'), findsOneWidget);

    // Overflow → discard → confirmation dialog.
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard workout'));
    await tester.pumpAndSettle();
    expect(find.text('Discard workout?'), findsOneWidget);

    // Backing out keeps the session alive.
    await tester.tap(find.text('Keep workout'));
    await tester.pumpAndSettle();
    expect(find.text('Finish'), findsOneWidget);
    expect(await db.select(db.workouts).get(), hasLength(1));

    // Confirming throws everything away and pops back to Home.
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(find.text('Start Workout'), findsOneWidget);
    expect(await db.select(db.workouts).get(), isEmpty);
    expect(await db.select(db.workoutSets).get(), isEmpty);
    await endApp(tester);
  });
}
