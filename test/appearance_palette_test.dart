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
import 'package:kinetic/features/settings/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Round 9.2 — Appearance: the theme-mode segments, the accent palette
/// swatches and the reset-to-default row drive settings + the visible
/// ThemeData.
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
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 2000);
    addTearDown(tester.view.reset);
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

  /// Round 2: Settings is reached through the shell drawer.
  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Settings'),
      60,
      scrollable: find
          .descendant(of: find.byType(Drawer), matching: find.byType(Scrollable))
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
  }

  Future<void> scrollSettingsTo(WidgetTester tester, Finder target) async {
    final list = find.descendant(
      of: find.byType(SettingsPage),
      matching: find.byType(ListView),
    );
    for (var i = 0;
        i < 8 && !target.hitTestable().evaluate().isNotEmpty;
        i++) {
      await tester.drag(list, const Offset(0, -300));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('accent swatch switches the accent and persists', (tester) async {
    await pumpApp(tester);
    await openSettings(tester);
    await scrollSettingsTo(tester, find.byKey(const Key('accent-ocean')));

    final ocean = AppAccent.byId('ocean').color;
    var app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    // Shipped look before the tap…
    expect(app.themeMode, ThemeMode.dark);
    expect(app.darkTheme!.colorScheme.primary, AppColors.accent);

    await tester.tap(find.byKey(const Key('accent-ocean')));
    await tester.pumpAndSettle();

    // …then both themes seed from the chosen accent.
    app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.darkTheme!.colorScheme.primary, ocean);
    expect(app.theme!.colorScheme.primary, ocean);
    expect(
      ProviderScope.containerOf(
              tester.element(find.byKey(const Key('accent-ocean'))))
          .read(settingsProvider)
          .accent,
      'ocean',
    );
    expect(prefs.getString('accent'), 'ocean');

    await endApp(tester);
  });

  testWidgets('theme mode segments persist and seed System/Light',
      (tester) async {
    await pumpApp(tester);
    await openSettings(tester);
    await scrollSettingsTo(tester, find.text('Light'));

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);
    expect(find.byKey(const Key('amoled-black-toggle')), findsNothing,
        reason: 'AMOLED is a dark-only concept');
    expect(prefs.getString('theme'), 'light');

    await endApp(tester);
  });

  testWidgets('reset to default restores the shipped look', (tester) async {
    SharedPreferences.setMockInitialValues({
      'theme': 'light',
      'accent': 'ocean',
      'amoled_black': true,
    });
    prefs = await SharedPreferences.getInstance();
    await pumpApp(tester);
    await openSettings(tester);
    await scrollSettingsTo(tester, find.byKey(const Key('theme-mode-segments')));

    // AMOLED lives under dark only — go dark first so the reset's third
    // dimension (amoled_black) is visible too.
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    await scrollSettingsTo(tester, find.byKey(const Key('appearance-reset')));
    expect(find.byKey(const Key('amoled-black-toggle')), findsOneWidget);

    await tester.tap(find.byKey(const Key('appearance-reset')));
    await tester.pumpAndSettle();
    expect(find.text('Reset appearance?'), findsOneWidget);
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(app.darkTheme!.colorScheme.primary, AppColors.accent);
    expect(app.darkTheme!.extension<AmoledTokens>()!.enabled, isFalse);
    expect(prefs.getString('accent'), 'kinetic');
    expect(prefs.getString('theme'), 'dark');
    expect(prefs.getBool('amoled_black'), isFalse);

    await endApp(tester);
  });
}
