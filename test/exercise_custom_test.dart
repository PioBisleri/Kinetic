import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/app.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/database/seed_service.dart';
import 'package:kinetic/core/settings/settings.dart';
import 'package:lottie/lottie.dart';
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

  /// Must be the LAST call in every test (see widget_test.dart): unmounts
  /// the tree so Drift streams and tickers wind down cleanly.
  Future<void> endApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  /// The library has two scrollables (horizontal chips + the list) and the
  /// detail player starts an infinite ticker — navigate the library list
  /// against its own scrollable.
  Future<void> scrollLibraryTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
  }

  /// Opening a detail route mounts Lottie, whose repeat() ticker never
  /// settles — advance a fixed amount instead of pumpAndSettle.
  Future<void> pumpRouteTransition(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  // ------------------------------- seeds ----------------------------------

  test('seed wires Tier-0 animation refs and preserves chest heat nodes',
      () async {
    final bench = await (db.select(db.exercises)
          ..where((e) => e.id.equals('barbell-bench-press')))
        .getSingle();
    expect(bench.animationKind, 'lottie');
    expect(bench.animationRef, 'assets/anim/press.json');

    final plank = await (db.select(db.exercises)
          ..where((e) => e.id.equals('plank')))
        .getSingle();
    expect(plank.animationKind, 'none');
    expect(plank.animationRef, isNull);

    // chest is both a display-group id and a leaf: seeding must not
    // clobber the leaf's heatmap nodes (the heat map reads this column).
    final chest = await (db.select(db.muscleGroups)
          ..where((m) => m.id.equals('chest')))
        .getSingle();
    expect(jsonDecode(chest.heatmapNodes), ['front.chest_l', 'front.chest_r']);
    expect(chest.orderIndex, 0);

    final back = await (db.select(db.muscleGroups)
          ..where((m) => m.id.equals('back')))
        .getSingle();
    expect(jsonDecode(back.heatmapNodes), isEmpty);
  });

  // --------------------------- custom exercises ---------------------------

  testWidgets('create → detail → edit → delete a custom exercise',
      (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Routines'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-library')));
    await tester.pumpAndSettle();

    // --- create ---
    await tester.tap(find.byKey(const Key('create-exercise')));
    await tester.pumpAndSettle();
    expect(find.text('New Exercise'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('exercise-name')),
      'Custom Hack Squat',
    );

    // Save without a primary muscle → inline error, stays on the form.
    await tester.tap(find.byKey(const Key('exercise-save')));
    await tester.pumpAndSettle();
    expect(find.text('Primary muscle required'), findsOneWidget);
    expect(find.text('New Exercise'), findsOneWidget);

    // Pick the primary muscle through the dropdown.
    final primaryButton = find.descendant(
      of: find.byKey(const Key('exercise-primary')),
      matching: find.byType(DropdownButton<String>),
    );
    await tester.tap(primaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chest').last); // menu entry, above the list
    await tester.pumpAndSettle();
    expect(find.text('Primary muscle required'), findsNothing);

    // Secondary muscle chip (mid-form — bring it into view first).
    await tester.scrollUntilVisible(
      find.byKey(const Key('muscle-glutes')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('muscle-glutes')));
    await tester.pumpAndSettle();

    // Animation URL must be https (or empty).
    await tester.scrollUntilVisible(
      find.byKey(const Key('exercise-anim-url')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('exercise-anim-url')),
      'http://insecure.example.com/anim.json',
    );
    await tester.tap(find.byKey(const Key('exercise-save')));
    await tester.pumpAndSettle();
    expect(find.text('Must start with https://'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('exercise-anim-url')), '');
    await tester.tap(find.byKey(const Key('exercise-save')));
    await tester.pumpAndSettle();

    // Back on the library, the new exercise is listed.
    expect(find.text('Exercise Library'), findsOneWidget);
    await scrollLibraryTo(tester, find.text('Custom Hack Squat'));
    expect(find.text('Custom Hack Squat'), findsOneWidget);
    expect(find.textContaining('Custom'), findsWidgets);

    final custom = await (db.select(db.exercises)
          ..where((e) => e.isCustom.equals(true)))
        .get();
    expect(custom, hasLength(1));
    final row = custom.single;
    expect(row.name, 'Custom Hack Squat');
    expect(row.category, 'custom');
    expect(row.primaryMuscleId, 'chest');
    expect(row.ownerId, 'local');
    expect(row.animationKind, 'none');
    expect(row.deletedAt, isNull);

    final mapRows = await (db.select(db.exerciseMuscleMap)
          ..where((m) => m.exerciseId.equals(row.id)))
        .get();
    expect(mapRows, hasLength(2));
    final primary = mapRows.firstWhere((m) => m.muscleId == 'chest');
    expect(primary.contribution, 1.0);
    expect(primary.role, 'primary');
    final secondary = mapRows.firstWhere((m) => m.muscleId == 'glutes');
    expect(secondary.contribution, 0.4);
    expect(secondary.role, 'secondary');

    // --- detail (no animation → static placeholder, settle-safe) ---
    await tester.tap(find.text('Custom Hack Squat'));
    await tester.pumpAndSettle();
    expect(find.text('Custom exercise'), findsOneWidget);
    expect(find.byKey(const Key('anim-placeholder')), findsOneWidget);
    expect(find.text('No animation'), findsOneWidget);
    expect(find.byKey(const Key('contribution-chest')), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget); // glutes secondary
    expect(find.byKey(const Key('edit-exercise')), findsOneWidget);
    expect(find.byKey(const Key('delete-exercise')), findsOneWidget);

    // --- edit ---
    await tester.tap(find.byKey(const Key('edit-exercise')));
    await tester.pumpAndSettle();
    expect(find.text('Edit Exercise'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('exercise-name')),
      'Custom Hack Squat v2',
    );
    await tester.tap(find.byKey(const Key('exercise-save')));
    await tester.pumpAndSettle();
    expect(find.text('Custom Hack Squat v2'), findsOneWidget);

    final renamed = await (db.select(db.exercises)
          ..where((e) => e.id.equals(row.id)))
        .getSingle();
    expect(renamed.name, 'Custom Hack Squat v2');

    // --- delete ---
    await tester.tap(find.byKey(const Key('delete-exercise')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Delete Custom Hack Squat v2?'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('confirm-delete')));
    await tester.pumpAndSettle();

    expect(find.text('Exercise Library'), findsOneWidget);
    expect(find.text('Custom Hack Squat v2'), findsNothing);

    final tombstoned = await (db.select(db.exercises)
          ..where((e) => e.id.equals(row.id)))
        .getSingle();
    expect(tombstoned.deletedAt, isNotNull);
    expect(await db.exerciseCountOnce(), 89); // back to the seeded catalog
    await endApp(tester);
  });

  testWidgets('detail shows Tier-0 Lottie for seeded exercise and a '
      'placeholder when no animation exists', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Routines'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-library')));
    await tester.pumpAndSettle();

    // Bench press → Tier-0 Lottie player.
    await scrollLibraryTo(tester, find.text('Barbell Bench Press'));
    await tester.tap(find.text('Barbell Bench Press'));
    await pumpRouteTransition(tester);

    expect(find.byType(Lottie), findsOneWidget); // animation wired up
    expect(find.byKey(const Key('edit-exercise')), findsNothing);
    expect(find.byKey(const Key('delete-exercise')), findsNothing);
    expect(find.byKey(const Key('contribution-chest')), findsOneWidget);
    expect(find.text('100%'), findsOneWidget); // chest
    expect(find.text('50%'), findsOneWidget); // triceps
    expect(find.text('40%'), findsOneWidget); // front delts
    expect(find.text('barbell'), findsOneWidget); // equipment chip
    expect(find.text('Weight × reps'), findsOneWidget);

    // Pop back to the library (Lottie disposes as the route leaves).
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(find.text('Exercise Library'), findsOneWidget);

    // Plank has no animation → placeholder instead of a player.
    await scrollLibraryTo(tester, find.text('Plank'));
    await tester.tap(find.text('Plank'));
    await tester.pumpAndSettle();
    expect(find.byType(Lottie), findsNothing);
    expect(find.byKey(const Key('anim-placeholder')), findsOneWidget);
    expect(find.text('No animation'), findsOneWidget);
    await endApp(tester);
  });
}
