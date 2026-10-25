import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/app.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/database/seed_service.dart';
import 'package:kinetic/core/settings/settings.dart';
import 'package:kinetic/features/workout/live_workout_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Round 4/14 — the shell drawer: an opaque ledger index, tab shortcuts
/// mirroring the bottom bar, and the non-tab destinations.
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

  /// Unmount first (same contract as widget_test): otherwise Drift stream
  /// cancellation and the logger's tickers trip the pending-timer invariant.
  Future<void> endApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  Future<void> openDrawer(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
  }

  testWidgets('drawer is an opaque ledger index carrying the navigation set', (
    tester,
  ) async {
    await pumpApp(tester);
    await openDrawer(tester);

    // Opaque ledger sheet — no blur, no translucent panel.
    expect(
      find.descendant(
        of: find.byType(Drawer),
        matching: find.byType(BackdropFilter),
      ),
      findsNothing,
    );
    final drawer = tester.widget<Drawer>(find.byType(Drawer));
    expect(drawer.backgroundColor!.a, 1.0);

    // The shell dims the page behind the separate ledger sheet.
    final shell = tester.widget<Scaffold>(
      find.byWidgetPredicate((s) => s is Scaffold && s.drawer != null),
    );
    expect(shell.drawerScrimColor, Colors.black.withValues(alpha: 0.45));

    // Header + Start Workout + tabs + app destinations + version footer.
    expect(find.text('KINETIC'), findsOneWidget);
    expect(find.text('Offline-first training log'), findsOneWidget);
    expect(find.byKey(const Key('drawer-start-workout')), findsOneWidget);
    expect(find.text('SESSION'), findsOneWidget);
    expect(find.text('NAVIGATE'), findsOneWidget);
    for (var i = 0; i < 5; i++) {
      expect(find.byKey(Key('drawer-tab-$i')), findsOneWidget);
    }

    // Route tiles sit below the fold — scroll the ledger index to the tail.
    var drawerScrollable = find
        .descendant(of: find.byType(Drawer), matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(
      find.byKey(const Key('drawer-settings')),
      100,
      scrollable: drawerScrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('APP'), findsOneWidget);
    expect(find.byKey(const Key('drawer-library')), findsOneWidget);
    expect(find.byKey(const Key('drawer-diet')), findsOneWidget);
    expect(find.byKey(const Key('drawer-schedule')), findsOneWidget);
    expect(find.byKey(const Key('drawer-settings')), findsOneWidget);
    expect(find.text('Kinetic · offline-first'), findsOneWidget);

    await endApp(tester);
  });

  testWidgets('drawer tab shortcuts switch branches and tint the active row', (
    tester,
  ) async {
    await pumpApp(tester);
    await openDrawer(tester);

    // Home is the visible branch → its ledger row is marked selected.
    Finder selectedRow(int tab) => find.ancestor(
      of: find.byKey(Key('drawer-tab-$tab')),
      matching: find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.selected == true,
      ),
    );
    expect(selectedRow(0), findsOneWidget);
    expect(selectedRow(1), findsNothing);

    await tester.tap(find.byKey(const Key('drawer-tab-2')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Analytics'), findsOneWidget);
    expect(find.byType(Drawer), findsNothing); // drawer closed behind us

    // Reopen: the shortcut moved the shell, so the active row follows.
    await openDrawer(tester);
    expect(selectedRow(0), findsNothing);
    expect(selectedRow(2), findsOneWidget);

    await endApp(tester);
  });

  testWidgets('Start Workout in the drawer boots the live logger', (
    tester,
  ) async {
    await pumpApp(tester);
    await openDrawer(tester);

    await tester.tap(find.byKey(const Key('drawer-start-workout')));
    await tester.pumpAndSettle();

    expect(find.byType(LiveWorkoutPage), findsOneWidget);
    expect(find.text('Finish'), findsOneWidget);
    expect(find.byType(Drawer), findsNothing);
    await endApp(tester);
  });

  testWidgets('drawer reaches the Exercise Library and Settings', (
    tester,
  ) async {
    await pumpApp(tester);
    await openDrawer(tester);
    var drawerScrollable = find
        .descendant(of: find.byType(Drawer), matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(
      find.byKey(const Key('drawer-library')),
      100,
      scrollable: drawerScrollable,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('drawer-library')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Exercise Library'), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    await openDrawer(tester);
    // Settings sits below the fold in the test viewport; scroll the ledger
    // index until the route tile exists, then tap.
    drawerScrollable = find
        .descendant(of: find.byType(Drawer), matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(
      find.byKey(const Key('drawer-settings')),
      100,
      scrollable: drawerScrollable,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('drawer-settings')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);

    await endApp(tester);
  });
}
