import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/app.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/database/seed_service.dart';
import 'package:kinetic/core/settings/settings.dart';
import 'package:kinetic/core/theme/app_theme.dart';
import 'package:kinetic/features/workout/live_workout_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Round 4 — the shell drawer: frosted-glass panel (blur + translucent tint
/// from the app's own tokens), tab shortcuts mirroring the bottom bar, and
/// the non-tab destinations.
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

  testWidgets('drawer is frosted glass carrying the full navigation set',
      (tester) async {
    await pumpApp(tester);
    await openDrawer(tester);

    // Frosted glass: a blur filter with the app-tinted translucent panel
    // behind it (60% of the theme surface — dark, light or AMOLED). The
    // tint is a Material so ListTiles can still paint on it.
    final blur = find.descendant(
      of: find.byType(Drawer),
      matching: find.byType(BackdropFilter),
    );
    expect(blur, findsOneWidget);
    final tint = tester.widget<Material>(
      find.descendant(of: blur, matching: find.byType(Material)).first,
    );
    expect(tint.color, AppColors.surface.withValues(alpha: 0.60));

    // The shell keeps a light scrim so the blurred page stays readable.
    final shell = tester.widget<Scaffold>(
      find.byWidgetPredicate((s) => s is Scaffold && s.drawer != null),
    );
    expect(shell.drawerScrimColor, Colors.black.withValues(alpha: 0.35));

    // Header + Start Workout + tabs + app destinations + version footer.
    expect(find.text('KINETIC'), findsOneWidget);
    expect(find.text('Offline-first training log'), findsOneWidget);
    expect(find.byKey(const Key('drawer-start-workout')), findsOneWidget);
    expect(find.text('NAVIGATE'), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      expect(find.byKey(Key('drawer-tab-$i')), findsOneWidget);
    }
    expect(find.text('APP'), findsOneWidget);
    expect(find.byKey(const Key('drawer-library')), findsOneWidget);
    expect(find.byKey(const Key('drawer-schedule')), findsOneWidget);
    expect(find.byKey(const Key('drawer-settings')), findsOneWidget);
    expect(find.text('Kinetic 0.1.4 · offline-first'), findsOneWidget);

    await endApp(tester);
  });

  testWidgets('drawer tab shortcuts switch branches and tint the active row',
      (tester) async {
    await pumpApp(tester);
    await openDrawer(tester);

    // Home is the visible branch → its row uses the filled icon in teal.
    Icon iconOf(int tab) => tester.widget<Icon>(find.descendant(
          of: find.byKey(Key('drawer-tab-$tab')),
          matching: find.byType(Icon),
        ));
    expect(iconOf(0).icon, Icons.play_circle_rounded);
    expect(iconOf(0).color, AppColors.accent);
    expect(iconOf(1).icon, Icons.list_alt_rounded);
    expect(iconOf(1).color, AppColors.textSecondary);

    await tester.tap(find.byKey(const Key('drawer-tab-2')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Analytics'), findsOneWidget);
    expect(find.byType(Drawer), findsNothing); // drawer closed behind us

    // Reopen: the shortcut moved the shell, so the active row follows.
    await openDrawer(tester);
    expect(iconOf(2).icon, Icons.insights);
    expect(iconOf(2).color, AppColors.accent);

    await endApp(tester);
  });

  testWidgets('Start Workout in the drawer boots the live logger',
      (tester) async {
    await pumpApp(tester);
    await openDrawer(tester);

    await tester.tap(find.byKey(const Key('drawer-start-workout')));
    await tester.pumpAndSettle();

    expect(find.byType(LiveWorkoutPage), findsOneWidget);
    expect(find.text('Finish'), findsOneWidget);
    expect(find.byType(Drawer), findsNothing);
    await endApp(tester);
  });

  testWidgets('drawer reaches the Exercise Library and Settings',
      (tester) async {
    await pumpApp(tester);
    await openDrawer(tester);

    await tester.tap(find.byKey(const Key('drawer-library')));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(AppBar, 'Exercise Library'), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    await openDrawer(tester);
    await tester.tap(find.byKey(const Key('drawer-settings')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);

    await endApp(tester);
  });
}
