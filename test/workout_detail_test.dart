import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/settings/settings.dart';
import 'package:kinetic/features/workout/application/workout_detail_provider.dart';
import 'package:kinetic/features/workout/workout_detail_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late SharedPreferences prefs;
  var seq = 0;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    await db.close();
  });

  Future<String> seed() async {
    final exerciseId = 'ex-${++seq}';
    await db.exercises.insertOnConflictUpdate(ExercisesCompanion.insert(
      id: exerciseId,
      name: exerciseName,
      mechanics: 'compound',
      primaryMuscleId: 'chest',
      updatedAt: DateTime(2026, 10, 17, 9),
    ));

    final wid = 'history-w-${++seq}';
    await db.workouts.insertOnConflictUpdate(WorkoutsCompanion.insert(
      id: wid,
      userId: 'local',
      startedAt: DateTime(2026, 10, 17, 19, 30),
      status: const Value('completed'),
      updatedAt: DateTime(2026, 10, 17, 19, 30),
      durationSec: const Value(3900),
      notes: const Value('Felt strong'),
    ));

    // One warm-up (never completed) + two working sets + one drop set.
    for (var i = 0; i < 3; i++) {
      await db.workoutSets.insertOnConflictUpdate(
        WorkoutSetsCompanion.insert(
          id: '$wid-s$i',
          workoutId: wid,
          exerciseId: exerciseId,
          orderIndex: i,
          weightKg: Value(60 + i * 2.5),
          reps: const Value(5),
          setType: Value(i == 0 ? 'warmup' : 'working'),
          isCompleted: Value(i != 0),
          updatedAt: DateTime(2026, 10, 17, 19, 31),
          loggedAt: Value(DateTime(2026, 10, 17, 19, 31)),
        ),
      );
    }
    await db.workoutSets.insertOnConflictUpdate(
      WorkoutSetsCompanion.insert(
        id: '$wid-drop',
        workoutId: wid,
        exerciseId: exerciseId,
        orderIndex: 3,
        setType: const Value('drop'),
        weightKg: const Value(50),
        reps: const Value(8),
        isCompleted: const Value(true),
        updatedAt: DateTime(2026, 10, 17, 19, 32),
        loggedAt: Value(DateTime(2026, 10, 17, 19, 32)),
      ),
    );
    return wid;
  }

  Widget page(String workoutId) => ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(home: WorkoutDetailPage(workoutId: workoutId)),
      );

  test('provider groups sets by exercise; totals match Home tile semantics',
      () async {
    final wid = await seed();
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    final detail =
        await container.read(workoutDetailProvider(wid).future);

    expect(detail, isNotNull);
    expect(detail!.title, 'Workout'); // no routine row seeded
    expect(detail.groups, hasLength(1));
    expect(detail.groups.single.sets, hasLength(4));
    // setCount = every completed set (warm-up excluded by completion flag).
    expect(detail.setCount, 3);
    // volume = completed hard sets only: 62.5·5 + 65·5 + 50·8.
    expect(detail.volumeKg, closeTo(62.5 * 5 + 65 * 5 + 50 * 8, 0.01));
  });

  test('provider returns null for a workout that no longer exists', () async {
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    expect(await container.read(workoutDetailProvider('nope').future), isNull);
  });

  testWidgets('page renders header, totals and per-set rows', (tester) async {
    final wid = await seed();

    await tester.pumpWidget(page(wid));
    await tester.pumpAndSettle();

    // Header + note.
    expect(find.text('Workout'), findsOneWidget);
    expect(find.textContaining('19:30'), findsOneWidget);
    expect(find.textContaining('1h 5m'), findsOneWidget);
    expect(find.text('Felt strong'), findsOneWidget);

    // Totals line: 3 completed sets, hard-set volume.
    expect(find.textContaining('3 sets'), findsOneWidget);

    // In-file, the exercise block groups every set in logged order.
    expect(find.text(exerciseName), findsOneWidget);

    // Warm-up badge + drop badge.
    expect(find.text('W'), findsOneWidget);
    expect(find.text('D'), findsOneWidget);

    // Weight × reps in kg (display default).
    expect(find.textContaining('62.5 kg × 5'), findsOneWidget);
    expect(find.textContaining('50 kg × 8'), findsOneWidget);

    // Exactly one uncompleted row (the warm-up) keeps the dimmed radio icon.
    expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
  });
}

const exerciseName = 'Barbell Bench Press';
