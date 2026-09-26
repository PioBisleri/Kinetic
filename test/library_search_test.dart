import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/app.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/database/seed_service.dart';
import 'package:kinetic/core/settings/settings.dart';
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

  /// Routines tab → full-screen Exercise Library route.
  Future<void> openLibrary(WidgetTester tester) async {
    await tester.tap(find.text('Routines'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-library')));
    await tester.pumpAndSettle();
  }

  testWidgets('typo search still finds exercises and reports matches',
      (tester) async {
    await pumpApp(tester);
    await openLibrary(tester);
    expect(find.textContaining('exercises'), findsOneWidget);

    // "bnch" — one typo off "bench": the fuzzy tier finds the bench press.
    await tester.enterText(find.byKey(const Key('library-search')), 'bnch');
    await tester.pumpAndSettle();
    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.text('Treadmill Run'), findsNothing); // no near-match
    expect(find.textContaining('matches'), findsOneWidget);

    // The clear (×) button restores the full catalog and the plain count.
    await tester.tap(find.byKey(const Key('library-search-clear')));
    await tester.pumpAndSettle();
    expect(find.textContaining('exercises'), findsOneWidget);
    expect(find.textContaining('matches'), findsNothing);
    await endApp(tester);
  });

  testWidgets('metadata words match rows that lack them in the name',
      (tester) async {
    await pumpApp(tester);
    await openLibrary(tester);

    // "cardio" is Treadmill Run's category, never part of its name.
    await tester.enterText(find.byKey(const Key('library-search')), 'cardio');
    await tester.pumpAndSettle();
    expect(find.text('Treadmill Run'), findsOneWidget);
    expect(find.text('Barbell Bench Press'), findsNothing);

    // A nonsense query shows an explicit empty state, not a blank list.
    await tester.enterText(
        find.byKey(const Key('library-search')), 'zzzqqq');
    await tester.pumpAndSettle();
    expect(find.text('No exercises match "zzzqqq"'), findsOneWidget);
    await endApp(tester);
  });
}
