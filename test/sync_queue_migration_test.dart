import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/database/seed_service.dart';

/// Round 7 schema upgrade: drop the never-used sync_queue table (v8).
///
/// The sync engine does dirty-scans on synced_at/updated_at instead of
/// queueing rows, so sync_queue was written by nothing and read by nothing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await SeedService(db).ensureSeeded();
  });

  tearDown(() => db.close());

  Future<bool> tableExists(String name) async {
    final rows = await db.customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable.withString(name)],
    ).get();
    return rows.isNotEmpty;
  }

  /// Recreate [table] without [drop] columns, simulating an older schema.
  Future<void> downgrade(String table, String ddl,
      {Set<String> drop = const {}}) async {
    final columns = await db.customSelect('PRAGMA table_info($table)').get();
    final names = [for (final r in columns) r.data['name'] as String];
    final keep = names.toSet().difference(drop).join(', ');
    await db.customStatement('CREATE TABLE ${table}_old ($ddl)');
    await db.customStatement(
        'INSERT INTO ${table}_old ($keep) SELECT $keep FROM $table');
    await db.customStatement('DROP TABLE $table');
    await db.customStatement('ALTER TABLE ${table}_old RENAME TO $table');
  }

  test('v7 → v8 drops sync_queue', () async {
    // Simulate a v7 database: sync_queue exists (created by createAll in v7).
    await db.customStatement('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        target_table TEXT NOT NULL,
        row_id TEXT NOT NULL,
        op TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        retries INTEGER NOT NULL DEFAULT 0
      )
    ''');
    expect(await tableExists('sync_queue'), isTrue);

    await db.migration.onUpgrade(Migrator(db), 7, 8);

    expect(await tableExists('sync_queue'), isFalse);
  });

  test('v1 → v8 upgrade replays every branch including the drop', () async {
    // Simulate a v1 database: create sync_queue, then downgrade tables
    // that gained columns in v3–v6.
    await db.customStatement('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        target_table TEXT NOT NULL,
        row_id TEXT NOT NULL,
        op TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        retries INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.customStatement('DROP TABLE ${db.weeklyPlans.actualTableName}');
    await db.customStatement('DROP TABLE body_metrics');
    await db.customStatement('DROP TABLE volume_landmarks');

    await downgrade(
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
    await downgrade(
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
    await downgrade(
      'profiles',
      '''
      updated_at INTEGER NOT NULL, synced_at INTEGER, deleted_at INTEGER,
      id TEXT NOT NULL, username TEXT,
      unit_system TEXT NOT NULL DEFAULT 'kg',
      theme TEXT NOT NULL DEFAULT 'dark',
      bodyweight_kg REAL, PRIMARY KEY (id)
      ''',
      drop: const {
        'height_cm',
        'birth_date',
        'sex',
        'body_fat_pct',
        'training_goal',
      },
    );

    // from = 1 runs ALL branches: v2..v8.
    await db.migration.onUpgrade(Migrator(db), 1, 8);

    // v8: sync_queue dropped.
    expect(await tableExists('sync_queue'), isFalse);
    // All other tables still exist after the full upgrade.
    expect(await tableExists('profiles'), isTrue);
    expect(await tableExists('weekly_plans'), isTrue);
    expect(await tableExists('body_metrics'), isTrue);
    expect(await tableExists('volume_landmarks'), isTrue);
  });
}
