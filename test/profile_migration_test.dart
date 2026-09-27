import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/database/seed_service.dart';

/// Round 5 schema upgrade: the "Your data" profile columns (v4).
///
/// Rebuilds `profiles` into its v3 shape (SQLite can add columns but not
/// drop them), then runs the app's own `onUpgrade` branch — the exact
/// code a Round 3/4 install executes the first time it opens Round 5.
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

  /// `profiles` as Round 3/4 created it (v3).
  const profilesV3Ddl = '''
    updated_at INTEGER NOT NULL, synced_at INTEGER, deleted_at INTEGER,
    id TEXT NOT NULL, username TEXT,
    unit_system TEXT NOT NULL DEFAULT 'kg',
    theme TEXT NOT NULL DEFAULT 'dark',
    bodyweight_kg REAL, PRIMARY KEY (id)
  ''';

  /// The five columns v4 adds to `profiles`.
  const v4ProfileColumns = [
    'height_cm',
    'birth_date',
    'sex',
    'body_fat_pct',
    'training_goal',
  ];

  Future<List<String>> profileColumns() async {
    final cols = await db.customSelect('PRAGMA table_info(profiles)').get();
    return [for (final r in cols) r.data['name'] as String];
  }

  Future<void> downgradeProfiles() =>
      downgradeTo('profiles', profilesV3Ddl, drop: v4ProfileColumns.toSet());

  test('v3 → v4 adds the Your data columns, existing row untouched',
      () async {
    // A profile as a Round 4 user would have it.
    await db.profiles.insertOnConflictUpdate(ProfilesCompanion.insert(
      id: 'local',
      updatedAt: DateTime.now(),
      username: const Value('Pio'),
      unitSystem: const Value('lbs'),
      bodyweightKg: const Value(82.5),
    ));

    await downgradeProfiles();
    expect(await profileColumns(), isNot(contains('height_cm')));

    // The exact branch a Round 4 install runs on first Round 5 launch.
    await db.migration.onUpgrade(Migrator(db), 3, 4);

    final names = await profileColumns();
    expect(names, containsAll(v4ProfileColumns));

    // Old data survives; new columns read NULL until the user fills them.
    final row = await (db.profiles.select()
          ..where((p) => p.id.equals('local')))
        .getSingle();
    expect(row.username, 'Pio');
    expect(row.unitSystem, 'lbs');
    expect(row.bodyweightKg, 82.5);
    expect(row.heightCm, isNull);
    expect(row.birthDate, isNull);
    expect(row.sex, isNull);
    expect(row.bodyFatPct, isNull);
    expect(row.trainingGoal, isNull);

    // The new columns are writable immediately after the upgrade.
    await db.profiles.insertOnConflictUpdate(ProfilesCompanion.insert(
      id: 'local',
      updatedAt: DateTime.now(),
      heightCm: const Value(180),
      birthDate: const Value('1996-03-04'),
      sex: const Value('other'),
      bodyFatPct: const Value(14.5),
      trainingGoal: const Value('hypertrophy'),
    ));
    final updated = await (db.profiles.select()
          ..where((p) => p.id.equals('local')))
        .getSingle();
    expect(updated.heightCm, 180);
    expect(updated.birthDate, '1996-03-04');
    expect(updated.sex, 'other');
    expect(updated.bodyFatPct, 14.5);
    expect(updated.trainingGoal, 'hypertrophy');
    expect(updated.bodyweightKg, 82.5); // partial upsert kept it
  });

  test('v1 → v4 upgrade still replays every earlier branch', () async {
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
      drop: const {'rest_seconds'},
    );
    await downgradeProfiles();

    // from = 1 runs ALL branches: v2 table, v3 columns, v4 profile.
    await db.migration.onUpgrade(Migrator(db), 1, 4);

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

    // v3: per-type counts exist on routine_exercises.
    final reCols =
        await db.customSelect('PRAGMA table_info(routine_exercises)').get();
    final reNames = [for (final r in reCols) r.data['name']];
    expect(
        reNames, containsAll(['warmup_sets', 'drop_sets', 'failure_sets']));

    // v4: Your data columns exist on profiles.
    expect(await profileColumns(), containsAll(v4ProfileColumns));
  });
}
