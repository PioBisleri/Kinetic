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
import 'package:kinetic/features/routines/exercise_detail_page.dart';
import 'package:kinetic/features/routines/exercise_edit_page.dart';
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

  /// Route transitions settle normally now that Lottie is gone.
  Future<void> pumpRouteTransition(WidgetTester tester) async {
    await tester.pumpAndSettle();
  }

  /// The page's own primary scrollable. Scope to the page *and* take
  /// `.first`: a descendant match also hits a TextField's internal
  /// Scrollable, which sits deeper in the same subtree — dragging that one
  /// only scrolls the text field (horizontally), never the page.
  Finder pageScrollable(Type page) => find
      .descendant(of: find.byType(page), matching: find.byType(Scrollable))
      .first;

  // ------------------------------- seeds ----------------------------------

  test('seed leaves exercises animation-free and preserves chest heat nodes',
      () async {
    final bench = await (db.select(db.exercises)
          ..where((e) => e.id.equals('barbell-bench-press')))
        .getSingle();
    expect(bench.animationKind, 'none');
    expect(bench.animationRef, isNull);

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

    // Save the finished form.
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

    // --- detail (settle-safe) ---
    await tester.tap(find.text('Custom Hack Squat'));
    await tester.pumpAndSettle();
    expect(find.text('Custom exercise'), findsOneWidget);

    // The progress card joins this screen above the muscle rows, which can
    // push the contributions past the ListView's build window — scroll them
    // into the tree before asserting.
    await tester.scrollUntilVisible(
      find.text('40%'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

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

  testWidgets('detail shows edit rules and muscle contributions for a '
      'seeded exercise', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Routines'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-library')));
    await tester.pumpAndSettle();

    // Bench press → seeded-exercise detail.
    await scrollLibraryTo(tester, find.text('Barbell Bench Press'));
    await tester.tap(find.text('Barbell Bench Press'));
    await pumpRouteTransition(tester);

    // Seeded exercises: editable, never deletable.
    expect(find.byKey(const Key('edit-exercise')), findsOneWidget);
    expect(find.byKey(const Key('delete-exercise')), findsNothing);
    expect(find.byKey(const Key('contribution-chest')), findsOneWidget);
    expect(find.text('100%'), findsOneWidget); // chest
    expect(find.text('50%'), findsOneWidget); // triceps
    expect(find.text('40%'), findsOneWidget); // front delts
    expect(find.text('barbell'), findsOneWidget); // equipment chip
    expect(find.text('Weight × reps'), findsOneWidget);

    // Pop back to the library.
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(find.text('Exercise Library'), findsOneWidget);

    // Plank opens with the same seeded-exercise edit rules.
    await scrollLibraryTo(tester, find.text('Plank'));
    await tester.tap(find.text('Plank'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('edit-exercise')), findsOneWidget);

    // Seeded round-trip: the editor opens prefilled, and saving unchanged
    // keeps the row seeded with its exact contribution weights.
    final mapBefore = await (db.select(db.exerciseMuscleMap)
          ..where((m) => m.exerciseId.equals('plank')))
        .get();
    expect(mapBefore, isNotEmpty);
    await tester.tap(find.byKey(const Key('edit-exercise')));
    await tester.pumpAndSettle();
    expect(find.text('Edit Exercise'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('exercise-name')))
          .controller!
          .text,
      'Plank',
    );
    await tester.tap(find.byKey(const Key('exercise-save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('edit-exercise')), findsOneWidget); // detail

    final plankAfter = await (db.select(db.exercises)
          ..where((e) => e.id.equals('plank')))
        .getSingle();
    expect(plankAfter.isCustom, isFalse);
    final mapAfter = await (db.select(db.exerciseMuscleMap)
          ..where((m) => m.exerciseId.equals('plank')))
        .get();
    expect(
      mapAfter.map((m) => '${m.muscleId}:${m.contribution}').toSet(),
      mapBefore.map((m) => '${m.muscleId}:${m.contribution}').toSet(),
    );
    await endApp(tester);
  });

  testWidgets('secondary contribution slider round-trips a free % value',
      (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Routines'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-library')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('create-exercise')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('exercise-name')),
      'Cable Fly Variant',
    );

    // Primary muscle: Chest.
    await tester.tap(find.descendant(
      of: find.byKey(const Key('exercise-primary')),
      matching: find.byType(DropdownButton<String>),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chest').last); // menu entry, above the list
    await tester.pumpAndSettle();

    // Selecting a secondary reveals its contribution row at 40% default.
    await tester.scrollUntilVisible(
      find.byKey(const Key('muscle-glutes')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('muscle-glutes')));
    await tester.pumpAndSettle();
    final slider = find.byKey(const Key('contribution-slider-glutes'));
    await tester.scrollUntilVisible(
      slider,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(slider, findsOneWidget);
    expect(find.text('40%'), findsOneWidget);

    // Free value — 73%, not a fixed preset.
    tester.widget<Slider>(slider).onChanged!(0.73);
    await tester.pumpAndSettle();
    expect(find.text('73%'), findsOneWidget);

    await tester.tap(find.byKey(const Key('exercise-save')));
    await tester.pumpAndSettle();

    // Wired through to the weighted muscle map …
    final created = await (db.select(db.exercises)
          ..where((e) => e.name.equals('Cable Fly Variant')))
        .getSingle();
    final mapRows = await (db.select(db.exerciseMuscleMap)
          ..where((m) => m.exerciseId.equals(created.id)))
        .get();
    expect(
      mapRows.firstWhere((m) => m.muscleId == 'glutes').contribution,
      closeTo(0.73, 0.0001),
    );
    expect(mapRows.firstWhere((m) => m.muscleId == 'chest').contribution, 1.0);

    // … shown on the detail page …
    await scrollLibraryTo(tester, find.text('Cable Fly Variant'));
    await tester.tap(find.text('Cable Fly Variant'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('73%'),
      200,
      scrollable: pageScrollable(ExerciseDetailPage),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('contribution-glutes')), findsOneWidget);
    expect(find.text('73%'), findsOneWidget);

    // … and it survives an open → save round trip through the editor.
    await tester.tap(find.byKey(const Key('edit-exercise')));
    await tester.pumpAndSettle();
    expect(find.text('Edit Exercise'), findsOneWidget); // editor opened
    final roundTrip = find.byKey(const Key('contribution-slider-glutes'));
    await tester.scrollUntilVisible(
      roundTrip,
      200,
      scrollable: pageScrollable(ExerciseEditPage),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<Slider>(roundTrip).value,
      closeTo(0.73, 0.0001),
    );
    expect(find.text('73%'), findsOneWidget);
    await tester.tap(find.byKey(const Key('exercise-save')));
    await tester.pumpAndSettle();
    final again = await (db.select(db.exerciseMuscleMap)
          ..where((m) => m.exerciseId.equals(created.id)))
        .get();
    expect(
      again.firstWhere((m) => m.muscleId == 'glutes').contribution,
      closeTo(0.73, 0.0001),
    );
    await endApp(tester);
  });

  testWidgets('exercise rest override: default → custom → back to default',
      (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Routines'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-library')));
    await tester.pumpAndSettle();
    await scrollLibraryTo(tester, find.text('Barbell Bench Press'));
    await tester.tap(find.text('Barbell Bench Press'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit-exercise')));
    await tester.pumpAndSettle();

    // The rest row lives below "How it's logged".
    await tester.scrollUntilVisible(
      find.byKey(const Key('exercise-rest-default')),
      200,
      scrollable: pageScrollable(ExerciseEditPage),
    );
    await tester.pumpAndSettle();

    // Seeded exercises have no override → chip ON, Settings default shown.
    final chip = tester.widget<FilterChip>(
      find.byKey(const Key('exercise-rest-default')),
    );
    expect(chip.selected, isTrue);
    expect(find.text('Uses Settings default'), findsOneWidget);

    // Leave Default → seeds from the working default (90 s).
    await tester.tap(find.byKey(const Key('exercise-rest-default')));
    await tester.pumpAndSettle();
    expect(find.text('1m 30s'), findsOneWidget);

    // −15 → 1m 15s, saved to the row.
    await tester.tap(find.byKey(const Key('exercise-rest-minus')));
    await tester.pumpAndSettle();
    expect(find.text('1m 15s'), findsOneWidget);
    await tester.tap(find.byKey(const Key('exercise-save')));
    await tester.pumpAndSettle();
    final saved = await (db.select(db.exercises)
          ..where((e) => e.id.equals('barbell-bench-press')))
        .getSingle();
    expect(saved.restSeconds, 75);

    // Re-open → round trip → then hand it back to the defaults.
    await tester.tap(find.byKey(const Key('edit-exercise')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('exercise-rest-default')),
      200,
      scrollable: pageScrollable(ExerciseEditPage),
    );
    await tester.pumpAndSettle();
    expect(find.text('1m 15s'), findsOneWidget);

    await tester.tap(find.byKey(const Key('exercise-rest-default')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('exercise-save')));
    await tester.pumpAndSettle();
    final reset = await (db.select(db.exercises)
          ..where((e) => e.id.equals('barbell-bench-press')))
        .getSingle();
    expect(reset.restSeconds, isNull); // inherit again
    await endApp(tester);
  });

  testWidgets('exercise load increment: default → custom → back to default',
      (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Routines'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-library')));
    await tester.pumpAndSettle();
    await scrollLibraryTo(tester, find.text('Barbell Bench Press'));
    await tester.tap(find.text('Barbell Bench Press'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit-exercise')));
    await tester.pumpAndSettle();

    // The increment row sits below Rest between sets.
    final chipFinder = find.byKey(const Key('exercise-increment-default'));
    await tester.scrollUntilVisible(
      chipFinder,
      260,
      scrollable: pageScrollable(ExerciseEditPage),
    );
    await tester.ensureVisible(chipFinder);
    await tester.pumpAndSettle();

    // Seeded exercises have no override → chip ON, unit default shown.
    final chip = tester.widget<FilterChip>(chipFinder);
    expect(chip.selected, isTrue);
    expect(find.text('Uses 2.5 kg default'), findsOneWidget);

    // Leave Default → seeds from the unit step (2.5 kg).
    await tester.tap(chipFinder);
    await tester.pumpAndSettle();
    expect(find.text('2.5 kg'), findsOneWidget);

    // −0.5 → 2 kg, saved to the row.
    await tester.tap(find.byKey(const Key('exercise-increment-minus')));
    await tester.pumpAndSettle();
    expect(find.text('2 kg'), findsOneWidget);
    await tester.tap(find.byKey(const Key('exercise-save')));
    await tester.pumpAndSettle();
    final saved = await (db.select(db.exercises)
          ..where((e) => e.id.equals('barbell-bench-press')))
        .getSingle();
    expect(saved.progressionIncrementKg, 2.0);

    // Re-open → round trip → then hand it back to the default.
    await tester.tap(find.byKey(const Key('edit-exercise')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      chipFinder,
      260,
      scrollable: pageScrollable(ExerciseEditPage),
    );
    await tester.ensureVisible(chipFinder);
    await tester.pumpAndSettle();
    expect(find.text('2 kg'), findsOneWidget);

    await tester.tap(chipFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('exercise-save')));
    await tester.pumpAndSettle();
    final reset = await (db.select(db.exercises)
          ..where((e) => e.id.equals('barbell-bench-press')))
        .getSingle();
    expect(reset.progressionIncrementKg, isNull); // inherit again
    await endApp(tester);
  });
}
