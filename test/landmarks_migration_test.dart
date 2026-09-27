import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/database/seed_service.dart';
import 'package:kinetic/core/utils/day_key.dart';
import 'package:kinetic/features/analytics/application/landmark_store.dart';
import 'package:kinetic/features/analytics/domain/volume_landmarks.dart';

/// Round 6 schema upgrade: the volume_landmarks table (v7). Create-only
/// by design — overrides live in rows and an absent muscle falls back to
/// the curated default, so the upgrade must NOT invent rows.
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

  test('v6 → v7 creates volume_landmarks with no backfill', () async {
    await db.customStatement('DROP TABLE volume_landmarks');
    expect(await tableExists('volume_landmarks'), isFalse);

    // The exact branch a Round 6 (6B) install runs on first 6C launch.
    await db.migration.onUpgrade(Migrator(db), 6, 7);

    expect(await tableExists('volume_landmarks'), isTrue);
    // Zero rows — defaults live in code, nothing is invented per muscle.
    expect(await db.volumeLandmarks.select().get(), isEmpty);
    expect(LandmarkStore.effective(const {}), landmarkDefaults);

    // …and the fresh table accepts an edit.
    await LandmarkStore(db)
        .save('chest', const Landmark(mev: 10, mav: 20, mrv: 25));
    final row = await (db.volumeLandmarks.select()
          ..where((v) => v.muscleId.equals('chest')))
        .getSingle();
    expect(row.mevSets, 10);
  });

  test('v1 → v7 upgrade still replays every earlier branch', () async {
    await db.profiles.insertOnConflictUpdate(ProfilesCompanion.insert(
      id: 'local',
      updatedAt: DateTime.now(),
      username: const Value('Pio'),
      bodyweightKg: const Value(80),
    ));
    await db.customSelect('SELECT 1').getSingle();
    await db.customStatement('DROP TABLE ${db.weeklyPlans.actualTableName}');
    await db.customStatement('DROP TABLE body_metrics');
    await db.customStatement('DROP TABLE volume_landmarks');

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

    // from = 1 runs ALL branches: v2..v7.
    await db.migration.onUpgrade(Migrator(db), 1, 7);

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

    // v3: count columns + rest override.
    final reCols =
        await db.customSelect('PRAGMA table_info(routine_exercises)').get();
    expect(
      [for (final r in reCols) r.data['name']],
      containsAll(['warmup_sets', 'drop_sets', 'failure_sets']),
    );

    // v4: Your data columns; the preserved weight survived the downgrade.
    final profile = await (db.profiles.select()
          ..where((p) => p.id.equals('local')))
        .getSingle();
    expect(profile.username, 'Pio');
    expect(profile.bodyweightKg, 80);
    expect(profile.heightCm, isNull);

    // v5: progression column, rows inherit.
    final exCols =
        await db.customSelect('PRAGMA table_info(exercises)').get();
    expect(
      [for (final r in exCols) r.data['name']],
      containsAll(['rest_seconds', 'progression_increment_kg']),
    );

    // v6: table created AND today's backfill ran off the preserved weight.
    expect(await tableExists('body_metrics'), isTrue);
    final rows = await db.bodyMetrics.select().get();
    expect(rows, hasLength(1));
    expect(rows.single.id, dayKey(DateTime.now()));
    expect(rows.single.weightKg, 80);

    // v7: table created, still empty — defaults, not rows.
    expect(await tableExists('volume_landmarks'), isTrue);
    expect(await db.volumeLandmarks.select().get(), isEmpty);
    expect(LandmarkStore.effective(const {}), landmarkDefaults);
  });
}
