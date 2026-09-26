import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/database/seed_service.dart';
import 'package:kinetic/features/routines/application/routine_repository.dart';

/// Round 3 schema upgrade: per-type set counts + custom rest.
///
/// Rebuilds both touched tables into their v2 shape (SQLite can add
/// columns but not drop them, so the test recreates them), then runs the
/// app's own `onUpgrade` branch — the exact code a Round 2 install
/// executes the first time it opens Round 3.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await SeedService(db).ensureSeeded();
  });

  tearDown(() => db.close());

  /// Rebuild [table] into its v2 shape (SQLite can add columns but not
  /// drop them): recreate with [ddl], copying every column it keeps.
  Future<void> downgradeToV2(
    String table,
    String ddl, {
    Set<String> drop = const {},
  }) async {
    final columns = await db.customSelect('PRAGMA table_info($table)').get();
    final names = [for (final r in columns) r.data['name'] as String];
    final keep = names.toSet().difference(drop).join(', ');
    await db.customStatement('CREATE TABLE ${table}_v2 ($ddl)');
    await db.customStatement(
        'INSERT INTO ${table}_v2 ($keep) SELECT $keep FROM $table');
    await db.customStatement('DROP TABLE $table');
    await db.customStatement('ALTER TABLE ${table}_v2 RENAME TO $table');
  }

  // Column lists as SQLite sees them (v3), minus the v3-only additions.
  const routineExercisesV2Ddl = '''
    updated_at INTEGER NOT NULL, synced_at INTEGER, deleted_at INTEGER,
    id TEXT NOT NULL, routine_id TEXT NOT NULL, exercise_id TEXT NOT NULL,
    order_index INTEGER NOT NULL, superset_group INTEGER,
    target_sets INTEGER NOT NULL DEFAULT 3,
    target_reps INTEGER NOT NULL DEFAULT 8,
    target_rpe REAL, target_weight REAL,
    rest_seconds INTEGER NOT NULL DEFAULT 90,
    is_warmup INTEGER NOT NULL DEFAULT 0,
    notes TEXT, PRIMARY KEY (id)
  ''';

  const exercisesV2Ddl = '''
    updated_at INTEGER NOT NULL, synced_at INTEGER, deleted_at INTEGER,
    id TEXT NOT NULL, name TEXT NOT NULL, mechanics TEXT NOT NULL,
    force_type TEXT, category TEXT NOT NULL DEFAULT 'barbell',
    primary_muscle_id TEXT NOT NULL,
    equipment TEXT NOT NULL DEFAULT '[]',
    default_metric TEXT NOT NULL DEFAULT 'weight_reps',
    animation_kind TEXT NOT NULL DEFAULT 'none',
    animation_ref TEXT, thumbnail_ref TEXT,
    is_custom INTEGER NOT NULL DEFAULT 0, owner_id TEXT,
    PRIMARY KEY (id)
  ''';

  test('v2 → v3 adds count/rest columns, backfills warm-up entries',
      () async {
    // A routine with one warm-up entry and one normal entry, as saved by
    // Round 2 (is_warmup flag, rest_seconds placeholder 90).
    final routineId = await RoutineRepository(db).saveRoutine(
      name: 'Push',
      entries: const [],
    );
    final now = DateTime.now();
    await db.routineExercises.insertOnConflictUpdate(RoutineExercisesCompanion.insert(
      id: 'warm-entry',
      routineId: routineId,
      exerciseId: 'face-pull',
      orderIndex: 0,
      targetSets: const Value(2),
      targetReps: const Value(15),
      isWarmup: const Value(true),
      restSeconds: const Value(90),
      updatedAt: now,
    ));
    await db.routineExercises.insertOnConflictUpdate(RoutineExercisesCompanion.insert(
      id: 'work-entry',
      routineId: routineId,
      exerciseId: 'barbell-bench-press',
      orderIndex: 1,
      updatedAt: now,
    ));
    // A custom exercise has no rest override (column doesn't exist yet).
    await db.exercises.insertOnConflictUpdate(ExercisesCompanion.insert(
      id: 'cus_test',
      name: 'My Lift',
      mechanics: 'compound',
      primaryMuscleId: 'chest',
      isCustom: const Value(true),
      ownerId: const Value('local'),
      updatedAt: now,
    ));

    await downgradeToV2(
      'routine_exercises',
      routineExercisesV2Ddl,
      drop: const {'warmup_sets', 'drop_sets', 'failure_sets'},
    );
    await downgradeToV2('exercises', exercisesV2Ddl,
        drop: const {'rest_seconds'});

    // The exact branch a Round 2 install runs on first Round 3 launch.
    await db.migration.onUpgrade(Migrator(db), 2, 3);

    // Warm-up entry: all 2 planned sets become warm-up sets.
    final warm =
        await (db.routineExercises.select()..where((e) => e.id.equals('warm-entry')))
            .getSingle();
    expect(warm.warmupSets, 2);
    expect(warm.dropSets, 0);
    expect(warm.failureSets, 0);
    expect(warm.targetSets, 2);
    // The never-user-editable 90 placeholder becomes "inherit".
    expect(warm.restSeconds, inheritRestSeconds);

    // Normal entry stays all-working with no override.
    final work =
        await (db.routineExercises.select()..where((e) => e.id.equals('work-entry')))
            .getSingle();
    expect(work.warmupSets, 0);
    expect(work.dropSets, 0);
    expect(work.failureSets, 0);
    expect(work.restSeconds, inheritRestSeconds);
    expect(work.targetSets, 3); // untouched

    // Exercise override column exists and defaults to "inherit".
    final ex =
        await (db.exercises.select()..where((e) => e.id.equals('cus_test')))
            .getSingle();
    expect(ex.restSeconds, isNull);

    // Both tables are fully usable after the upgrade.
    final newId = await RoutineRepository(db).saveRoutine(name: 'Legs', entries: [
      RoutineDraft(
        exerciseId: 'barbell-row',
        targetSets: 5,
        targetReps: 8,
        warmupSets: 1,
        dropSets: 1,
        failureSets: 1,
        restSeconds: 150,
      ),
    ]);
    final rows = await (db.routineExercises.select()
          ..where((e) => e.routineId.equals(newId)))
        .get();
    expect(rows.single.warmupSets, 1);
    expect(rows.single.dropSets, 1);
    expect(rows.single.failureSets, 1);
    expect(rows.single.restSeconds, 150);
  });

  test('v1 → v3 upgrade still creates the weekly plan and v3 columns',
      () async {
    await db.customSelect('SELECT 1').getSingle();
    await db.customStatement(
        'DROP TABLE ${db.weeklyPlans.actualTableName}');
    await downgradeToV2(
      'routine_exercises',
      routineExercisesV2Ddl,
      drop: const {'warmup_sets', 'drop_sets', 'failure_sets'},
    );
    await downgradeToV2('exercises', exercisesV2Ddl,
        drop: const {'rest_seconds'});

    // from = 1 runs BOTH branches (v2 table creation, then v3 columns).
    await db.migration.onUpgrade(Migrator(db), 1, 3);

    await db.weeklyPlans.insertOnConflictUpdate(WeeklyPlansCompanion.insert(
      weekday: Value(1),
      routineId: Value('push-day'),
      updatedAt: DateTime.now(),
    ));
    final plan = await (db.weeklyPlans.select()
          ..where((w) => w.weekday.equals(1)))
        .getSingle();
    expect(plan.routineId, 'push-day');

    final cols =
        await db.customSelect('PRAGMA table_info(routine_exercises)').get();
    final names = [for (final r in cols) r.data['name']];
    expect(names, containsAll(['warmup_sets', 'drop_sets', 'failure_sets']));
  });
}
