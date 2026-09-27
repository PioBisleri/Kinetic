import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/database/seed_service.dart';

/// Round 6 schema upgrade: the per-exercise progression increment (v5).
///
/// Rebuilds `exercises` into its v4 shape (SQLite can add columns but not
/// drop them), then runs the app's own `onUpgrade` branch — the exact
/// code a Round 5 install executes the first time it opens Round 6.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await SeedService(db).ensureSeeded();
  });

  tearDown(() => db.close());

  /// Rebuild [table] into its old shape: recreate with [ddl], copying
  /// every column it keeps.
  Future<void> downgradeTo(
    String table,
    String ddl, {
    Set<String> drop = const {},
  }) async {
    final columns = await db.customSelect('PRAGMA table_info($table)').get();
    final names = [for (final r in columns) r.data['name'] as String];
    final keep = names.toSet().difference(drop).join(', ');
    await db.customStatement('CREATE TABLE ${table}_old ($ddl)');
    await db.customStatement(
        'INSERT INTO ${table}_old ($keep) SELECT $keep FROM $table');
    await db.customStatement('DROP TABLE $table');
    await db.customStatement('ALTER TABLE ${table}_old RENAME TO $table');
  }

  /// The exercises table as Round 5 created it (v4): the rest override
  /// exists, the progression column does not.
  const exercisesV4Ddl = '''
    updated_at INTEGER NOT NULL, synced_at INTEGER, deleted_at INTEGER,
    id TEXT NOT NULL, name TEXT NOT NULL, mechanics TEXT NOT NULL,
    force_type TEXT, category TEXT NOT NULL DEFAULT 'barbell',
    primary_muscle_id TEXT NOT NULL,
    equipment TEXT NOT NULL DEFAULT '[]',
    default_metric TEXT NOT NULL DEFAULT 'weight_reps',
    animation_kind TEXT NOT NULL DEFAULT 'none',
    animation_ref TEXT, thumbnail_ref TEXT,
    is_custom INTEGER NOT NULL DEFAULT 0, owner_id TEXT,
    rest_seconds INTEGER,
    PRIMARY KEY (id)
  ''';

  Future<List<String>> exerciseColumns() async {
    final cols = await db.customSelect('PRAGMA table_info(exercises)').get();
    return [for (final r in cols) r.data['name'] as String];
  }

  test('v4 → v5 adds progression_increment_kg, rows default to inherit',
      () async {
    await downgradeTo('exercises', exercisesV4Ddl,
        drop: const {'progression_increment_kg'});
    expect(await exerciseColumns(),
        isNot(contains('progression_increment_kg')));

    // The exact branch a Round 5 install runs on first Round 6 launch.
    await db.migration.onUpgrade(Migrator(db), 4, 5);

    expect(await exerciseColumns(), contains('progression_increment_kg'));

    // Existing rows read NULL → follow the unit default, like before.
    final bench = await (db.exercises.select()
          ..where((e) => e.id.equals('barbell-bench-press')))
        .getSingle();
    expect(bench.progressionIncrementKg, isNull);
    expect(bench.restSeconds, isNull); // untouched by this branch

    // The new column is writable immediately after the upgrade.
    await (db.update(db.exercises)
          ..where((e) => e.id.equals('barbell-bench-press')))
        .write(const ExercisesCompanion(progressionIncrementKg: Value(1.25)));
    final updated = await (db.exercises.select()
          ..where((e) => e.id.equals('barbell-bench-press')))
        .getSingle();
    expect(updated.progressionIncrementKg, 1.25);
  });

  test('v1 → v5 upgrade still replays every earlier branch', () async {
    await db.customSelect('SELECT 1').getSingle();
    await db.customStatement('DROP TABLE ${db.weeklyPlans.actualTableName}');
    await downgradeTo(
      'routine_exercises',
      '''
      updated_at INTEGER NOT NULL, synced_at INTEGER, deleted_at INTEGER,
      id TEXT NOT NULL, routine_id TEXT NOT NULL, exercise_id TEXT NOT NULL,
      order_index INTEGER NOT NULL, superset_group INTEGER,
      target_sets INTEGER NOT NULL DEFAULT 3,
      target_reps INTEGER NOT NULL DEFAULT 8,
      target_rpe REAL, target_weight REAL,
      rest_seconds INTEGER NOT NULL DEFAULT 90,
      is_warmup INTEGER NOT NULL DEFAULT 0,
      notes TEXT, PRIMARY KEY (id)
      ''',
      drop: const {'warmup_sets', 'drop_sets', 'failure_sets'},
    );
    await downgradeTo(
      'exercises',
      '''
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
      ''',
      drop: const {'rest_seconds', 'progression_increment_kg'},
    );
    await downgradeTo(
      'profiles',
      '''
      updated_at INTEGER NOT NULL, synced_at INTEGER, deleted_at INTEGER,
      id TEXT NOT NULL, username TEXT,
      unit_system TEXT NOT NULL DEFAULT 'kg',
      theme TEXT NOT NULL DEFAULT 'dark',
      bodyweight_kg REAL, PRIMARY KEY (id)
      ''',
      drop: const {'height_cm', 'birth_date', 'sex', 'body_fat_pct',
        'training_goal'},
    );

    // from = 1 runs ALL branches: v2 table, v3 columns, v4 profile, v5 step.
    await db.migration.onUpgrade(Migrator(db), 1, 5);

    // v2: weekly plan table exists again.
    await db.weeklyPlans.insertOnConflictUpdate(WeeklyPlansCompanion.insert(
      weekday: const Value(1),
      routineId: const Value('push-day'),
      updatedAt: DateTime.now(),
    ));
    final plan = await (db.weeklyPlans.select()
          ..where((w) => w.weekday.equals(1)))
        .getSingle();
    expect(plan.routineId, 'push-day');

    // v3: per-type counts exist on routine_exercises, rest override on
    // exercises.
    final reCols =
        await db.customSelect('PRAGMA table_info(routine_exercises)').get();
    final reNames = [for (final r in reCols) r.data['name']];
    expect(
        reNames, containsAll(['warmup_sets', 'drop_sets', 'failure_sets']));

    // v4: Your data columns exist on profiles.
    final profileCols =
        await db.customSelect('PRAGMA table_info(profiles)').get();
    final pNames = [for (final r in profileCols) r.data['name']];
    expect(
        pNames,
        containsAll(['height_cm', 'birth_date', 'sex', 'body_fat_pct',
          'training_goal']));

    // v5: progression column exists and seeded rows inherit the default.
    expect(await exerciseColumns(),
        containsAll(['rest_seconds', 'progression_increment_kg']));
    final bench = await (db.exercises.select()
          ..where((e) => e.id.equals('barbell-bench-press')))
        .getSingle();
    expect(bench.progressionIncrementKg, isNull);
  });
}
