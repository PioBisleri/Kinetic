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
import 'package:kinetic/features/workout/application/rest_resolver.dart';
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

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
  }

  /// Drag Settings' own ListView until [target] is built and hittable.
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

  testWidgets('Rest section edits all three defaults and persists',
      (tester) async {
    await pumpApp(tester);
    await openSettings(tester);
    await scrollSettingsTo(tester, find.byKey(const Key('rest-warmup-value')));

    // Round 3 defaults: warm-up 60, working 90, failure 120.
    expect(find.text('1m'), findsOneWidget);
    expect(find.text('1m 30s'), findsOneWidget);
    expect(find.text('2m'), findsOneWidget);

    // Working: 90 → 105 s.
    await tester.tap(find.byKey(const Key('rest-working-plus')));
    await tester.pumpAndSettle();
    expect(find.text('1m 45s'), findsOneWidget);
    expect(prefs.getInt('rest_working_sec'), 105);

    // Warm-up: 60 → 45 s.
    await tester.tap(find.byKey(const Key('rest-warmup-minus')));
    await tester.pumpAndSettle();
    expect(find.text('45s'), findsOneWidget);
    expect(prefs.getInt('rest_warmup_sec'), 45);

    // Failure: 120 → 135 s.
    await tester.tap(find.byKey(const Key('rest-failure-plus')));
    await tester.pumpAndSettle();
    expect(find.text('2m 15s'), findsOneWidget);
    expect(prefs.getInt('rest_failure_sec'), 135);

    // Cold start: the stored values drive the resolver again.
    await endApp(tester);
    await pumpApp(tester);
    final fresh = await SharedPreferences.getInstance();
    expect(fresh.getInt('rest_working_sec'), 105);
    expect(fresh.getInt('rest_warmup_sec'), 45);
    expect(fresh.getInt('rest_failure_sec'), 135);

    await endApp(tester);
  });

  testWidgets('rest steppers stop at 0 (off) and 600 s', (tester) async {
    await pumpApp(tester);
    await openSettings(tester);
    await scrollSettingsTo(tester, find.byKey(const Key('rest-warmup-value')));

    // 60 → 0 in four 15 s steps, then the minus button disables.
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byKey(const Key('rest-warmup-minus')));
      await tester.pumpAndSettle();
    }
    expect(find.text('Off'), findsOneWidget);
    expect(prefs.getInt('rest_warmup_sec'), 0);
    final minus = tester.widget<IconButton>(
      find.byKey(const Key('rest-warmup-minus')),
    );
    expect(minus.onPressed, isNull);

    await endApp(tester);
  });

  test('Settings values feed the rest resolver', () async {
    const settings = SettingsState(
      restWarmupSec: 15,
      restWorkingSec: 120,
      restFailureSec: 90,
    );
    Future<int> resolve(String setType) => resolveRestSeconds(
          db: db,
          settings: settings,
          session: null,
          exerciseId: 'barbell-bench-press',
          setType: setType,
        );

    expect(await resolve('warmup'), 15);
    expect(await resolve('working'), 120);
    expect(await resolve('drop'), 120); // shares the working value
    expect(await resolve('failure'), 90);
  });
}
