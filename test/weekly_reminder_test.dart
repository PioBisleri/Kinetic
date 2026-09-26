import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/app.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/database/seed_service.dart';
import 'package:kinetic/core/settings/settings.dart';
import 'package:kinetic/features/settings/settings_page.dart';
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

  /// Round 2 moved units/appearance/reminders into Settings, reached
  /// through the shell drawer.
  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
  }

  /// Drag Settings' own ListView until [target] is built *and*
  /// hit-testable (a bare [Scrollable] finder is ambiguous here too).
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

  testWidgets('weekly reminder toggle reveals controls and persists',
      (tester) async {
    await pumpApp(tester);
    await openSettings(tester);

    await scrollSettingsTo(tester, find.byKey(const Key('reminder-toggle')));

    // Off by default: no day chips, no time row yet.
    final toggle = tester
        .widget<SwitchListTile>(find.byKey(const Key('reminder-toggle')));
    expect(toggle.value, isFalse);
    expect(find.byKey(const Key('reminder-day-1')), findsNothing);
    expect(find.byKey(const Key('reminder-time')), findsNothing);

    // Enable — controls appear with the defaults (Mon 18:00).
    await tester.tap(find.byKey(const Key('reminder-toggle')));
    await tester.pumpAndSettle();
    expect(prefs.getBool('reminder_enabled'), isTrue);
    await scrollSettingsTo(tester, find.byKey(const Key('reminder-time')));
    expect(find.byKey(const Key('reminder-day-1')), findsOneWidget);
    expect(find.byKey(const Key('reminder-time')), findsOneWidget);
    expect(find.text('18:00'), findsOneWidget);
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const Key('reminder-day-1')))
          .selected,
      isTrue,
    );

    // Pick a different day — selection + pref follow.
    await scrollSettingsTo(tester, find.byKey(const Key('reminder-day-4')));
    await tester.tap(find.byKey(const Key('reminder-day-4')));
    await tester.pumpAndSettle();
    expect(prefs.getInt('reminder_weekday'), 4);
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const Key('reminder-day-4')))
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const Key('reminder-day-1')))
          .selected,
      isFalse,
    );

    // Cold start keeps the whole reminder setup.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await pumpApp(tester);
    await openSettings(tester);
    await scrollSettingsTo(tester, find.byKey(const Key('reminder-day-4')));
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const Key('reminder-toggle')))
          .value,
      isTrue,
    );
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const Key('reminder-day-4')))
          .selected,
      isTrue,
    );
    expect(find.text('18:00'), findsOneWidget);

    // Disable — controls collapse and the pref clears. The toggle may sit
    // above the fold now, so bring it back into view first.
    await tester.ensureVisible(find.byKey(const Key('reminder-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reminder-toggle')));
    await tester.pumpAndSettle();
    expect(prefs.getBool('reminder_enabled'), isFalse);
    expect(find.byKey(const Key('reminder-day-4')), findsNothing);
    expect(find.byKey(const Key('reminder-time')), findsNothing);

    await endApp(tester);
  });
}
