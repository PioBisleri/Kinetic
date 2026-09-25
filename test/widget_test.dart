import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/app.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/database/seed_service.dart';
import 'package:kinetic/core/settings/settings.dart';
import 'package:kinetic/features/profile/profile_page.dart';
import 'package:kinetic/features/routines/application/routine_repository.dart';
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

  /// Must be the LAST call in every test: unmounting inside the test body
  /// makes Riverpod cancel Drift query streams, and elapsing the fake clock
  /// fires their 0-duration close-timers — otherwise the framework's
  /// "no pending timers" invariant fails (and each failure burns a
  /// 10-minute test timeout).
  Future<void> endApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  /// All mounted tabs stay alive in the shell and the bodyweight TextField
  /// has its own internal Scrollable, so scroll helpers can't just look for
  /// a [Scrollable] — drag the Profile page's [ListView] itself instead,
  /// until [target] is built (ListView children below the fold aren't).
  Future<void> scrollProfileUntil(
    WidgetTester tester,
    Finder target, {
    int maxDrags = 8,
  }) async {
    final list = find.descendant(
      of: find.byType(ProfilePage),
      matching: find.byType(ListView),
    );
    for (var i = 0; i < maxDrags && target.evaluate().isEmpty; i++) {
      await tester.drag(list, const Offset(0, -300));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('seeds the exercise catalog on first launch', (tester) async {
    await pumpApp(tester);
    final count = await db.exerciseCountOnce();
    expect(count, greaterThan(80));
    await endApp(tester);
  });

  testWidgets('renders the 4-tab shell with Home content', (tester) async {
    await pumpApp(tester);

    expect(find.text('Kinetic'), findsOneWidget);
    expect(find.text('Start Workout'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Routines'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    await endApp(tester);
  });

  testWidgets('navigates to Routines and lists seeded exercises',
      (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Routines'));
    await tester.pumpAndSettle();
    expect(find.text('No routines yet'), findsOneWidget);

    // Library moved to its own full-screen route behind the app bar icon.
    await tester.tap(find.byKey(const Key('open-library')));
    await tester.pumpAndSettle();

    expect(find.text('Exercise Library'), findsOneWidget);
    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.textContaining('exercises'), findsOneWidget);
    await endApp(tester);
  });

  testWidgets('category filter narrows the list', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Routines'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-library')));
    await tester.pumpAndSettle();

    expect(find.text('Cardio'), findsWidgets); // chips are eagerly built

    // The chip row can overflow the viewport — bring Cardio into view first.
    await tester.ensureVisible(find.text('Cardio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cardio'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(
      find.text('Incline Treadmill Walk'),
      findsOneWidget,
    ); // alphabetically first cardio entry (ListView builds lazily)
    expect(find.text('Barbell Bench Press'), findsNothing);
    await endApp(tester);
  });

  testWidgets('full logging flow: start → add exercise → log set → rest',
      (tester) async {
    await pumpApp(tester);

    // Home → start a session → live logger opens.
    await tester.tap(find.text('Start Workout'));
    await tester.pumpAndSettle();
    expect(find.text('Finish'), findsOneWidget);
    expect(find.text('No exercises yet.\nAdd your first exercise to begin.'),
        findsOneWidget);

    // Add an exercise through the searchable sheet.
    await tester.tap(find.byKey(const Key('add-exercise-empty')));
    await tester.pumpAndSettle();
    // Narrow the list with the search field (also keeps us viewport-safe).
    await tester.enterText(find.byType(TextField), 'bench');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Barbell Bench Press'));
    await tester.pumpAndSettle();
    expect(find.text('Barbell Bench Press'), findsWidgets);

    // Log a set via the big-target editor.
    await tester.tap(find.byKey(const Key('add-set-barbell-bench-press')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('set-weight-input')), '60');
    await tester.enterText(find.byKey(const Key('set-reps-input')), '5');
    await tester.ensureVisible(find.byKey(const Key('set-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('set-save')));
    await tester.pumpAndSettle();

    // Set row rendered + rest timer auto-started at 1:30.
    expect(find.text('60 kg × 5'), findsOneWidget);
    expect(find.text('1:30'), findsOneWidget);

    // Back home shows the in-progress card, not the start card.
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(find.text('WORKOUT IN PROGRESS'), findsOneWidget);
    expect(find.text('Resume Workout'), findsOneWidget);

    await endApp(tester);
  });

  testWidgets('build a routine end-to-end: targets, sets, superset',
      (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Routines'));
    await tester.pumpAndSettle();
    expect(find.text('No routines yet'), findsOneWidget);

    // Open the builder.
    await tester.tap(find.byKey(const Key('new-routine')));
    await tester.pumpAndSettle();
    expect(find.text('New Routine'), findsOneWidget);

    await tester.enterText(
        find.byKey(const Key('routine-name')), 'Push Day');

    // Add bench press through the searchable sheet.
    await tester.tap(find.byKey(const Key('add-routine-exercise')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('exercise-search')), 'bench press');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Barbell Bench Press'));
    await tester.pumpAndSettle();
    expect(find.text('Barbell Bench Press'), findsOneWidget);

    // 3 → 4 target sets, planned weight 60 kg.
    await tester.tap(find.byKey(const Key('sets-plus-barbell-bench-press')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('target-weight-barbell-bench-press')), '60');
    await tester.pumpAndSettle();

    // Second exercise + superset link from bench → incline.
    await tester.tap(find.byKey(const Key('add-routine-exercise')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('exercise-search')), 'incline dumbbell');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Incline Dumbbell Press'));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const Key('superset-barbell-bench-press')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('routine-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('routine-save')));
    await tester.pumpAndSettle();

    // Back on the list: card with aggregated counts.
    expect(find.text('Push Day'), findsOneWidget);
    expect(find.text('2 exercises · 7 sets'), findsOneWidget);
    await endApp(tester);
  });

  testWidgets('start a routine: planned sets complete and start rest',
      (tester) async {
    final repo = RoutineRepository(db);
    final id = await repo.saveRoutine(name: 'Leg Day', entries: [
      RoutineDraft(
          exerciseId: 'barbell-back-squat',
          targetSets: 3,
          targetReps: 5,
          targetWeight: 100),
      RoutineDraft(
          exerciseId: 'leg-press',
          targetSets: 2,
          targetReps: 10,
          targetWeight: 140),
    ]);

    await pumpApp(tester);
    await tester.tap(find.text('Routines'));
    await tester.pumpAndSettle();
    expect(find.text('Leg Day'), findsOneWidget);
    expect(find.text('2 exercises · 5 sets'), findsOneWidget);

    await tester.tap(find.byKey(Key('start-routine-$id')));
    await tester.pumpAndSettle();

    // Live logger pre-populated with the routine's planned sets.
    expect(find.text('Finish'), findsOneWidget);
    expect(find.text('Barbell Back Squat'), findsOneWidget);
    expect(find.text('100 kg × 5'), findsNWidgets(3));

    // Complete the first planned set → checked + rest timer auto-starts.
    await tester.tap(find.text('100 kg × 5').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('set-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('set-save')));
    await tester.pumpAndSettle();

    expect(find.text('1:30'), findsOneWidget); // working → 90s rest
    expect(find.byIcon(Icons.radio_button_unchecked),
        findsWidgets); // remaining planned rows are hollow

    // Home reflects the running session (we popped back to Routines).
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(find.text('WORKOUT IN PROGRESS'), findsNothing);
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('WORKOUT IN PROGRESS'), findsOneWidget);

    await endApp(tester);
  });

  testWidgets('reorder exercises in the builder persists new order',
      (tester) async {
    final repo = RoutineRepository(db);
    final id = await repo.saveRoutine(name: 'Pull Day', entries: [
      RoutineDraft(exerciseId: 'barbell-row', targetSets: 3, targetReps: 8),
      RoutineDraft(exerciseId: 'pull-up', targetSets: 3, targetReps: 8),
    ]);

    await pumpApp(tester);
    await tester.tap(find.text('Routines'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pull Day'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Routine'), findsOneWidget);
    expect(find.text('Barbell Bent-Over Row'), findsOneWidget);

    // Drag the first card's handle down past the second card.
    await tester.drag(
        find.byIcon(Icons.drag_handle).first, const Offset(0, 400));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('routine-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('routine-save')));
    await tester.pumpAndSettle();

    final rows = await (db.routineExercises.select()
          ..where((e) => e.routineId.equals(id))
          ..orderBy([(e) => OrderingTerm.asc(e.orderIndex)]))
        .get();
    expect(rows.map((e) => e.exerciseId).toList(),
        ['pull-up', 'barbell-row']);
    await endApp(tester);
  });

  testWidgets('Profile toggles persist units and theme', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    // Units sit at the top of the page — assert them before scrolling.
    await tester.tap(find.text('lbs'));
    await tester.pumpAndSettle();

    expect(prefs.getString('unit'), 'lbs');
    expect(
      ProviderScope.containerOf(
              tester.element(find.widgetWithText(AppBar, 'Profile')))
          .read(settingsProvider)
          .unit,
      UnitSystem.lbs,
    );

    // The privacy statement sits below the Sync section, so it may be
    // outside the initial viewport — bring it into view first.
    await scrollProfileUntil(tester, find.text('Fully private'));
    expect(find.text('Fully private'), findsOneWidget);
    await endApp(tester);
  });

  testWidgets('Profile shows sync + export sections when not configured',
      (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    // No dart-defines in tests → the sync section degrades to a status tile
    // and must never touch `Supabase.instance` (it asserts uninitialized).
    expect(find.text('Cloud sync not configured'), findsOneWidget);

    // The Data section sits at the bottom of the page — bring it into view.
    await scrollProfileUntil(tester, find.text('Export JSON backup'));
    expect(find.text('Export JSON backup'), findsOneWidget);
    expect(find.text('Export CSV'), findsOneWidget);
    await endApp(tester);
  });
}
