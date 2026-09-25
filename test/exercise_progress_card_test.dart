import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/app.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/database/seed_service.dart';
import 'package:kinetic/core/settings/settings.dart';
import 'package:kinetic/features/analytics/widgets/charts.dart';
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

  /// Unmounts the tree so Drift streams and tickers wind down cleanly —
  /// must be the LAST call in every test.
  Future<void> endApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  /// Navigate the library list against its own scrollable.
  Future<void> scrollLibraryTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
  }

  /// The detail player starts an infinite Lottie ticker — pumpAndSettle
  /// would never settle, so advance fixed steps instead.
  Future<void> pumpRouteTransition(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// Fixed-step detail-page scroll (Lottie rules out pumpAndSettle).
  Future<void> scrollDetailBy(WidgetTester tester, double dy) async {
    await tester.drag(find.byType(Scrollable).last, Offset(0, -dy));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets(
      'exercise detail: records, deltas, chart series toggle, empty state',
      (tester) async {
    // Two training days for bench: e1RM 70 → 75, volume 2000 → 2600.
    final now = DateTime.now();
    final d1 = DateTime(now.year, now.month, now.day - 14);
    final d2 = DateTime(now.year, now.month, now.day - 7);
    await db.exerciseHistory.insertOnConflictUpdate(
      ExerciseHistoryCompanion.insert(
        userId: 'local',
        exerciseId: 'barbell-bench-press',
        date: d1,
        bestE1Rm: const Value(70),
        topWeight: const Value(55),
        topReps: const Value(5),
        totalVolume: const Value(2000),
      ),
    );
    await db.exerciseHistory.insertOnConflictUpdate(
      ExerciseHistoryCompanion.insert(
        userId: 'local',
        exerciseId: 'barbell-bench-press',
        date: d2,
        bestE1Rm: const Value(75),
        topWeight: const Value(60),
        topReps: const Value(5),
        totalVolume: const Value(2600),
      ),
    );

    await pumpApp(tester);
    await tester.tap(find.text('Routines'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-library')));
    await tester.pumpAndSettle();

    await scrollLibraryTo(tester, find.text('Barbell Bench Press'));
    await tester.tap(find.text('Barbell Bench Press'));
    await pumpRouteTransition(tester);

    // Bring the progress card's top half into the tree/viewport.
    await scrollDetailBy(tester, 250);
    await scrollDetailBy(tester, 250);

    // Header + shared window chips.
    expect(find.text('Progress'), findsOneWidget);
    expect(find.byKey(const Key('period-12')), findsOneWidget);

    // Record tiles (all-time).
    expect(find.text('75 kg'), findsOneWidget); // best e1RM (d2)
    expect(find.text('60 × 5'), findsOneWidget); // heaviest set (d2)
    expect(find.text('2.6k kg'), findsOneWidget); // volume record (d2)
    expect(find.textContaining('Best e1RM'), findsOneWidget);
    expect(find.textContaining('Heaviest set'), findsOneWidget);
    expect(find.textContaining('Volume record'), findsOneWidget);

    // Chart defaults to the e1RM series; the toggle swaps it.
    expect(find.byKey(const Key('progress-chart')), findsOneWidget);
    var chart = tester
        .widget<ExerciseTrendChart>(find.byKey(const Key('progress-chart')));
    expect(chart.series, ExerciseSeries.e1rm);

    await tester.tap(find.byKey(const Key('series-volume')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    chart =
        tester.widget<ExerciseTrendChart>(find.byKey(const Key('progress-chart')));
    expect(chart.series, ExerciseSeries.volume);

    // Last session + signed deltas vs the session before it.
    await scrollDetailBy(tester, 300);
    expect(find.text('60 kg × 5'), findsOneWidget); // top set of d2
    expect(find.text('e1RM +5 kg'), findsOneWidget); // 75 − 70
    expect(find.text('Volume +600 kg'), findsOneWidget); // 2600 − 2000
    expect(find.text('vs previous'), findsOneWidget);

    // Back out, then an exercise with no history shows the invite.
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await scrollLibraryTo(tester, find.text('Plank'));
    await tester.tap(find.text('Plank'));
    await pumpRouteTransition(tester);
    expect(find.text('Log a session to see your progress.'), findsOneWidget);

    await endApp(tester);
  });
}
