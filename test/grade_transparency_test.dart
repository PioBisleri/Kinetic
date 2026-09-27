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
import 'package:kinetic/features/analytics/domain/grade_engine.dart';
import 'package:kinetic/features/analytics/widgets/grade_sheets.dart';
import 'package:kinetic/features/workout/domain/suggestion_engine.dart';
import 'package:kinetic/features/workout/widgets/suggestion_why_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Round 5 — algorithm transparency: "what the app thinks".
///
/// A grade chip tap opens the breakdown (formula + raw inputs + freshness
/// verdict + tier ladder), the card's info button opens "How grades
/// works", and the suggestion chip's info button explains double
/// progression with the active rule highlighted.
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

  group('freshnessVerdict', () {
    test('never trained', () {
      expect(GradeEngine.freshnessVerdict(double.infinity),
          'Never trained — consistency starts at 0');
    });

    test('fresh window (0–24h)', () {
      expect(GradeEngine.freshnessVerdict(0), 'Fresh — trained just now');
      expect(GradeEngine.freshnessVerdict(5), 'Fresh — trained 5h ago');
      expect(GradeEngine.freshnessVerdict(24), 'Fresh — trained 24h ago');
    });

    test('cooling (24–72h)', () {
      expect(GradeEngine.freshnessVerdict(30),
          'Cooling — trained 30h ago, credit is fading');
    });

    test('cold at and beyond the 72h window', () {
      expect(GradeEngine.freshnessVerdict(72), contains('Cold'));
      expect(GradeEngine.freshnessVerdict(200), contains('Cold'));
    });
  });

  testWidgets('grade chip tap opens the breakdown sheet', (tester) async {
    await seedWorkout(DateTime.now().subtract(const Duration(days: 1)));
    await pumpApp(tester);

    await tester.scrollUntilVisible(find.byKey(const Key('grade-chest')), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('grade-chest')));
    await tester.pumpAndSettle();

    expect(
      find.text('0.40 × Volume + 0.40 × Strength + 0.20 × Consistency'),
      findsOneWidget,
    );
    expect(find.text('Volume · 40%'), findsOneWidget);
    expect(find.text('Strength · 40%'), findsOneWidget);
    expect(find.text('Consistency · 20%'), findsOneWidget);
    expect(find.text('TIER THRESHOLDS'), findsOneWidget);
    expect(find.textContaining('rolling 30-day window'), findsOneWidget);

    // Dismissing the sheet returns to the board.
    Navigator.of(tester.element(find.text('TIER THRESHOLDS'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('TIER THRESHOLDS'), findsNothing);

    await endApp(tester);
  });

  testWidgets('the info button opens "How grades work"', (tester) async {
    await seedWorkout(DateTime.now().subtract(const Duration(days: 1)));
    await pumpApp(tester);

    // The header sits above the chips — scroll to it, then make sure it's
    // fully on-screen (scrollUntilVisible accepts cache-extent ghosts).
    await tester.scrollUntilVisible(find.byKey(const Key('chart-info')), 200);
    await tester.ensureVisible(find.byKey(const Key('chart-info')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chart-info')));
    await tester.pumpAndSettle();

    expect(find.text('How grades work'), findsOneWidget);
    expect(find.textContaining('Score = 0.40 × Volume'), findsOneWidget);
    expect(
      find.textContaining(
          'S ≥ 90 · A ≥ 78 · B ≥ 64 · C ≥ 48 · D ≥ 30 · F below 30'),
      findsOneWidget,
    );
    expect(find.textContaining('computed on-device from your own logs'),
        findsOneWidget);

    Navigator.of(tester.element(find.text('How grades work'))).pop();
    await tester.pumpAndSettle();

    await endApp(tester);
  });

  testWidgets('breakdown sheet spells out the raw inputs and verdict',
      (tester) async {
    final result = GradeEngine.grade(
      muscleId: 'chest',
      volumeKg30d: 2000,
      bestE1RmKg: 90,
      bodyweightKg: 80,
      daysTrained30d: 5,
      targetSessions: 8,
      hoursSinceTrained: 5,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              key: const Key('open-breakdown'),
              onPressed: () => showGradeBreakdownSheet(
                context,
                muscleName: 'Chest',
                result: result,
                volumeKg30d: 2000,
                bestE1RmKg: 90,
                bodyweightKg: 80,
                daysTrained30d: 5,
                targetSessions: 8,
                hoursSinceTrained: 5,
                unit: UnitSystem.kg,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open-breakdown')));
    await tester.pumpAndSettle();

    expect(find.text('Chest'), findsOneWidget);
    expect(find.textContaining('pts'), findsWidgets); // score + components
    expect(
      find.text('2,000 kg in 30 days · target 34,640 kg'),
      findsOneWidget,
    );
    expect(
      find.text('Best e1RM 90 kg · standard 80 kg (1× bodyweight)'),
      findsOneWidget,
    );
    expect(
      find.text('5 of 8 sessions in 30 days · 5h since last'),
      findsOneWidget,
    );
    expect(find.text('Fresh — trained 5h ago'), findsOneWidget);
    expect(find.text('TIER THRESHOLDS'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('suggestion why sheet highlights the active rule',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              key: const Key('open-why'),
              onPressed: () => showSuggestionWhySheet(
                context,
                suggestion: const Suggestion(
                  weightKg: 62.5,
                  action: SuggestionAction.progress,
                  reason: 'Hit 10 reps last session',
                ),
                unit: UnitSystem.kg,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open-why')));
    await tester.pumpAndSettle();

    expect(find.text('Why this suggestion?'), findsOneWidget);
    expect(
      find.text('62.5 kg · Hit 10 reps last session'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Double progression — the four rules'),
      findsOneWidget,
    );
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Repeat'), findsOneWidget);
    expect(find.text('Deload'), findsOneWidget);
    expect(find.textContaining('increments are 2.5 kg'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
