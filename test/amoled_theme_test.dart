import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/app.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/database/seed_service.dart';
import 'package:kinetic/core/settings/settings.dart';
import 'package:kinetic/core/theme/app_theme.dart';
import 'package:kinetic/features/profile/profile_page.dart';
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

  Future<void> endApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  /// Drag the Profile page's own ListView (the shell keeps all tabs alive
  /// and the bodyweight field has an internal Scrollable, so a bare
  /// [Scrollable] finder is ambiguous) until [target] is both built and
  /// hit-testable, i.e. tappable.
  Future<void> scrollProfileTo(WidgetTester tester, Finder target) async {
    final list = find.descendant(
      of: find.byType(ProfilePage),
      matching: find.byType(ListView),
    );
    for (var i = 0;
        i < 8 && !target.hitTestable().evaluate().isNotEmpty;
        i++) {
      await tester.drag(list, const Offset(0, -300));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('AMOLED black toggle swaps dark tokens and persists',
      (tester) async {
    await pumpApp(tester);

    // Default: dark theme without AMOLED.
    var app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.darkTheme!.scaffoldBackgroundColor, AppColors.background);
    expect(app.darkTheme!.extension<AmoledTokens>()!.enabled, isFalse);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    await scrollProfileTo(
        tester, find.byKey(const Key('amoled-black-toggle')));
    await tester.tap(find.byKey(const Key('amoled-black-toggle')));
    await tester.pumpAndSettle();

    // ThemeData tokens swapped to true black…
    app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(
        app.darkTheme!.scaffoldBackgroundColor, AppColors.amoledBackground);
    expect(app.darkTheme!.extension<AmoledTokens>()!.enabled, isTrue);
    expect(app.darkTheme!.cardTheme.color, AppColors.amoledSurface);

    // …and widget-facing accessors see the flag through the theme.
    final navContext = tester.element(find.byType(NavigationBar));
    expect(navContext.background, AppColors.amoledBackground);
    expect(navContext.surface, AppColors.amoledSurface);

    // State + preference persisted.
    expect(
      ProviderScope.containerOf(
              tester.element(find.widgetWithText(AppBar, 'Profile')))
          .read(settingsProvider)
          .amoledBlack,
      isTrue,
    );
    expect(prefs.getBool('amoled_black'), isTrue);

    // Cold start keeps the preference.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await pumpApp(tester);
    app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(
        app.darkTheme!.scaffoldBackgroundColor, AppColors.amoledBackground);

    await endApp(tester);
  });

  testWidgets('AMOLED switch only shows in dark mode', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    await scrollProfileTo(tester, find.byKey(const Key('dark-mode-toggle')));
    expect(find.byKey(const Key('amoled-black-toggle')), findsOneWidget);

    // Flip to light — the AMOLED option (a dark-only concept) disappears.
    await tester.tap(find.byKey(const Key('dark-mode-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('amoled-black-toggle')), findsNothing);

    // Back to dark it returns, off by default.
    await tester.tap(find.byKey(const Key('dark-mode-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('amoled-black-toggle')), findsOneWidget);
    final switchWidget = tester.widget<SwitchListTile>(
        find.byKey(const Key('amoled-black-toggle')));
    expect(switchWidget.value, isFalse);

    await endApp(tester);
  });
}
