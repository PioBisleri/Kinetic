import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/app.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/database/seed_service.dart';
import 'package:kinetic/core/settings/settings.dart';
import 'package:kinetic/features/routines/application/routine_repository.dart';
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

  Future<void> openNewRoutine(WidgetTester tester) async {
    await tester.tap(find.text('Routines'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('new-routine')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('routine-name')), 'Push Day');
    await tester.pumpAndSettle();
  }

  Future<void> addExercise(WidgetTester tester, String query) async {
    await tester.tap(find.byKey(const Key('add-routine-exercise')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('exercise-search')), query);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Barbell Bench Press'));
    await tester.pumpAndSettle();
  }

  Future<void> saveRoutine(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('routine-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('routine-save')));
    await tester.pumpAndSettle();
  }

  Future<List<RoutineExercise>> entries(String routineId) =>
      (db.routineExercises.select()
            ..where((e) => e.routineId.equals(routineId))
            ..orderBy([(e) => OrderingTerm.asc(e.orderIndex)]))
          .get();

  Future<RoutineExercise> singleEntryNamed(String name) async {
    final routine =
        await (db.routines.select()..where((r) => r.name.equals(name)))
            .getSingle();
    return (await entries(routine.id)).single;
  }

  testWidgets('type-count steppers derive working sets and persist',
      (tester) async {
    await pumpApp(tester);
    await openNewRoutine(tester);
    await addExercise(tester, 'bench press');

    // Defaults: 3 total, no typed counts → 3 working.
    expect(find.text('3 working'), findsOneWidget);

    // 2 warm-up sets → 1 working left.
    await tester.tap(find.byKey(const Key('warmup-plus-barbell-bench-press')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('warmup-plus-barbell-bench-press')));
    await tester.pumpAndSettle();
    expect(find.text('1 working'), findsOneWidget);

    // +1 failure: 2 + 1 = 3, so working drops to 0.
    await tester.tap(find.byKey(const Key('failure-plus-barbell-bench-press')));
    await tester.pumpAndSettle();
    expect(find.text('0 working'), findsOneWidget);

    // A 4th warm-up can't fit either — the total is already accounted for.
    await tester.tap(find.byKey(const Key('warmup-plus-barbell-bench-press')));
    await tester.pumpAndSettle();
    expect(find.text('0 working'), findsOneWidget); // unchanged

    await saveRoutine(tester);
    final row = await singleEntryNamed('Push Day');
    expect(row.targetSets, 3);
    expect(row.warmupSets, 2);
    expect(row.failureSets, 1);
    expect(row.dropSets, 0);
    expect(row.isWarmup, isTrue); // legacy flag mirrors "plans warm-ups"
    await endApp(tester);
  });

  testWidgets('lowering Sets clamps the typed counts back inside it',
      (tester) async {
    await pumpApp(tester);
    await openNewRoutine(tester);
    await addExercise(tester, 'bench press');

    await tester.tap(find.byKey(const Key('warmup-plus-barbell-bench-press')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('warmup-plus-barbell-bench-press')));
    await tester.pumpAndSettle();
    expect(find.text('1 working'), findsOneWidget); // 3 − 2

    await tester.tap(find.byKey(const Key('sets-minus-barbell-bench-press')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sets-minus-barbell-bench-press')));
    await tester.pumpAndSettle();
    // Total 1, warm-up pulled back to fit → 1 working.
    expect(find.text('1 working'), findsOneWidget);

    await saveRoutine(tester);
    final row = await singleEntryNamed('Push Day');
    expect(row.targetSets, 1);
    expect(row.warmupSets, 0);
    expect(row.isWarmup, isFalse);
    await endApp(tester);
  });

  testWidgets('rest override: Default chip → stepper → persisted',
      (tester) async {
    await pumpApp(tester);
    await openNewRoutine(tester);
    await addExercise(tester, 'bench press');

    // Starts on Default (inherit), so no value/steppers yet.
    final chip = tester.widget<FilterChip>(
      find.byKey(const Key('rest-barbell-bench-press-default')),
    );
    expect(chip.selected, isTrue);
    expect(
        find.byKey(const Key('rest-barbell-bench-press-value')),
        findsNothing);

    // Leave Default → seeds from the working default (90 s).
    await tester.tap(
        find.byKey(const Key('rest-barbell-bench-press-default')));
    await tester.pumpAndSettle();
    expect(find.text('1m 30s'), findsOneWidget);

    // +15 → 1m 45s.
    await tester
        .tap(find.byKey(const Key('rest-barbell-bench-press-plus')));
    await tester.pumpAndSettle();
    expect(find.text('1m 45s'), findsOneWidget);

    await saveRoutine(tester);
    expect((await singleEntryNamed('Push Day')).restSeconds, 105);
    await endApp(tester);
  });

  testWidgets('Back to Default stores the inherit sentinel', (tester) async {
    final routineId = await RoutineRepository(db).saveRoutine(
      name: 'Push Day',
      entries: const [
        RoutineDraft(
          exerciseId: 'barbell-bench-press',
          targetSets: 3,
          targetReps: 8,
          restSeconds: 150,
        ),
      ],
    );

    await pumpApp(tester);
    await tester.tap(find.text('Routines'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Push Day'));
    await tester.pumpAndSettle();
    expect(find.text('2m 30s'), findsOneWidget);

    await tester
        .tap(find.byKey(const Key('rest-barbell-bench-press-default')));
    await tester.pumpAndSettle();

    await saveRoutine(tester);
    expect((await entries(routineId)).single.restSeconds, inheritRestSeconds);
    await endApp(tester);
  });
}
