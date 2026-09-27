import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/app.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/database/seed_service.dart';
import 'package:kinetic/core/settings/settings.dart';
import 'package:kinetic/features/analytics/application/analytics_providers.dart';
import 'package:kinetic/features/analytics/application/rollup_service.dart';
import 'package:kinetic/features/analytics/domain/volume_landmarks.dart';
import 'package:kinetic/features/analytics/widgets/landmarks_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Round 6 — the volume-landmarks card: every muscle drawn against its
/// band, per-muscle edits with validation, and the transparency sheet.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late SharedPreferences prefs;
  var seq = 0;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await SeedService(db).ensureSeeded();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() => db.close());

  /// See analytics_page_test: balance pairs come from the bundle, whose
  /// futures never complete inside the FakeAsync test zone.
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
          balancePairsProvider.overrideWith((_) => Future.value([
                for (final p in (jsonDecode(
                        File('assets/seed/muscle_groups.json')
                            .readAsStringSync())['balance_pairs'] as List))
                  BalancePairConfig.fromJson(p as Map<String, dynamic>),
              ])),
        ],
        child: const KineticApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Analytics'));
    await tester.pumpAndSettle();
  }

  Future<void> endApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  /// One finished bench session yesterday → chest/front_delts/triceps
  /// each hold a single hard set in the rollup.
  Future<void> seedWorkout(DateTime day) async {
    final id = 'w-${seq++}';
    await db.workouts.insertOnConflictUpdate(WorkoutsCompanion.insert(
      id: id,
      userId: 'local',
      startedAt: day,
      updatedAt: day,
      status: const Value('completed'),
      endedAt: Value(day.add(const Duration(hours: 1))),
      durationSec: const Value(3600),
      totalVolume: const Value(0),
    ));
    await db.workoutSets.insertOnConflictUpdate(WorkoutSetsCompanion.insert(
      id: 's-$id',
      workoutId: id,
      exerciseId: 'barbell-bench-press',
      orderIndex: 0,
      setType: const Value('working'),
      weightKg: const Value(60),
      reps: const Value(5),
      isCompleted: const Value(true),
      loggedAt: Value(day),
      updatedAt: day,
    ));
    await RollupService(db).recomputeDay(day);
  }

  /// Opens Analytics and scrolls the landmarks card into view.
  Future<void> openCard(WidgetTester tester) async {
    await pumpApp(tester);
    await tester.scrollUntilVisible(find.text('Volume landmarks'), 200);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Volume landmarks'));
    await tester.pumpAndSettle();
  }

  testWidgets('the card lists every gradeable muscle against its band',
      (tester) async {
    await seedWorkout(DateTime.now().subtract(const Duration(days: 1)));
    await openCard(tester);

    expect(
      find.text('hard sets per week · last 12 weeks'),
      findsOneWidget,
    );

    // All 18 muscles, and only those: no parent groups, no cardio.
    for (final id in landmarkDefaults.keys) {
      expect(find.byKey(Key('landmark-$id')), findsOneWidget, reason: id);
    }
    expect(find.byKey(const Key('landmark-back')), findsNothing);
    expect(find.byKey(const Key('landmark-cardio')), findsNothing);

    // The trained muscle shows its dose; an untrained one sits at zero.
    final chest = find.byKey(const Key('landmark-chest'));
    expect(
      find.descendant(of: chest, matching: find.text('1')),
      findsOneWidget,
    );
    expect(
      find.descendant(
          of: chest, matching: find.text('MEV 8 · MAV 18 · MRV 22')),
      findsOneWidget,
    );
    final lats = find.byKey(const Key('landmark-lats'));
    expect(
      find.descendant(of: lats, matching: find.text('0')),
      findsOneWidget,
    );
    expect(
      find.descendant(
          of: lats, matching: find.text('MEV 8 · MAV 16 · MRV 22')),
      findsOneWidget,
    );

    await endApp(tester);
  });

  testWidgets('tapping a muscle edits its numbers, validated and resettable',
      (tester) async {
    await seedWorkout(DateTime.now().subtract(const Duration(days: 1)));
    await openCard(tester);

    final chest = find.byKey(const Key('landmark-chest'));
    await tester.ensureVisible(chest);
    await tester.pumpAndSettle();
    await tester.tap(chest);
    await tester.pumpAndSettle();

    // Prefilled with the chest defaults.
    expect(
      find.descendant(
          of: find.byKey(const Key('landmark-mev-input')),
          matching: find.text('8')),
      findsOneWidget,
    );
    expect(
      find.descendant(
          of: find.byKey(const Key('landmark-mav-input')),
          matching: find.text('18')),
      findsOneWidget,
    );

    // Out-of-order values are rejected and the sheet stays open.
    await tester.enterText(
        find.byKey(const Key('landmark-mav-input')), '5');
    await tester.tap(find.byKey(const Key('landmark-save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('landmark-error')), findsOneWidget);
    expect(find.text('Edit landmarks'), findsOneWidget);

    // A valid edit saves, closes, and the card reflects it.
    await tester.enterText(
        find.byKey(const Key('landmark-mav-input')), '20');
    await tester.tap(find.byKey(const Key('landmark-save')));
    await tester.pumpAndSettle();
    expect(find.text('Edit landmarks'), findsNothing);
    expect(
      find.descendant(
          of: chest, matching: find.text('MEV 8 · MAV 20 · MRV 22')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: chest, matching: find.text('edited')),
      findsOneWidget,
    );
    final row = await (db.volumeLandmarks.select()
          ..where((v) => v.muscleId.equals('chest')))
        .getSingle();
    expect(row.mavSets, 20);

    // Reopening shows the edit flag and Reset restores the default.
    await tester.ensureVisible(chest);
    await tester.pumpAndSettle();
    await tester.tap(chest);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('landmark-reset')), findsOneWidget);
    await tester.tap(find.byKey(const Key('landmark-reset')));
    await tester.pumpAndSettle();
    expect(await db.volumeLandmarks.select().get(), isEmpty);
    expect(
      find.descendant(
          of: chest, matching: find.text('MEV 8 · MAV 18 · MRV 22')),
      findsOneWidget,
    );

    await endApp(tester);
  });

  testWidgets('the info button explains how the bands are counted',
      (tester) async {
    await seedWorkout(DateTime.now().subtract(const Duration(days: 1)));
    await openCard(tester);

    await tester.tap(find.descendant(
      of: find.byType(VolumeLandmarksCard),
      matching: find.byKey(const Key('landmarks-info')),
    ));
    await tester.pumpAndSettle();

    expect(find.text('How landmarks work'), findsOneWidget);
    expect(find.textContaining('Minimum effective'), findsOneWidget);
    expect(
      find.textContaining('same sets that feed the volume charts'),
      findsOneWidget,
    );
    expect(find.text('Sweet spot'), findsOneWidget); // zone legend
    expect(find.textContaining('curated defaults'), findsOneWidget);

    // Dismissing the sheet returns to the card.
    Navigator.of(tester.element(find.text('How landmarks work'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('How landmarks work'), findsNothing);

    await endApp(tester);
  });
}
