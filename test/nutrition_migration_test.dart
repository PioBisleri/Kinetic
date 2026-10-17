import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/database/seed_service.dart';
import 'package:kinetic/core/utils/day_key.dart';

/// Round 8 schema upgrade (v9): the body_metrics water/steps columns and
/// the two fresh nutrition tables. Additive only — no backfill, nothing
/// invented for history.
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

  Future<List<String>> columns(String table) async {
    final rows = await db.customSelect('PRAGMA table_info($table)').get();
    return [for (final r in rows) r.data['name'] as String];
  }

  test('v8 → v9 adds water_ml/steps and creates foods/food_logs', () async {
    // A weigh-in logged before the upgrade must survive it.
    await db.bodyMetrics.insertOnConflictUpdate(BodyMetricsCompanion.insert(
      id: dayKey(DateTime.now()),
      updatedAt: DateTime.now(),
      weightKg: const Value(90),
    ));

    // Rebuild body_metrics at its v8 shape and drop the v9 tables so the
    // branch has real work to do (the fresh test DB is already at v9).
    await db.customStatement('DROP TABLE IF EXISTS foods');
    await db.customStatement('DROP TABLE IF EXISTS food_logs');
    final cols = await columns('body_metrics');
    final keep = cols
        .where((c) => c != 'water_ml' && c != 'steps')
        .join(', ');
    await db.customStatement('''
      CREATE TABLE body_metrics_old (
        updated_at INTEGER NOT NULL, synced_at INTEGER, deleted_at INTEGER,
        id TEXT NOT NULL, weight_kg REAL, PRIMARY KEY (id)
      )
    ''');
    await db.customStatement(
      'INSERT INTO body_metrics_old ($keep) SELECT $keep FROM body_metrics',
    );
    await db.customStatement('DROP TABLE body_metrics');
    await db.customStatement('ALTER TABLE body_metrics_old RENAME TO body_metrics');
    expect(await columns('body_metrics'), isNot(contains('water_ml')));

    // The exact branch an existing install runs on its first v9 launch.
    await db.migration.onUpgrade(Migrator(db), 8, 9);

    expect(await columns('body_metrics'), containsAll(['water_ml', 'steps']));
    expect(await tableExists('foods'), isTrue);
    expect(await tableExists('food_logs'), isTrue);

    // The pre-upgrade weigh-in survived with null health columns.
    final row = await db.bodyMetricOnce(dayKey(DateTime.now()));
    expect(row!.weightKg, 90);
    expect(row.waterMl, isNull);
    expect(row.steps, isNull);
  });

  test('v1 → v9 replay: earlier branches still run before the new one',
      () async {
    await db.profiles.insertOnConflictUpdate(ProfilesCompanion.insert(
      id: 'local',
      updatedAt: DateTime.now(),
      username: const Value('Pio'),
      bodyweightKg: const Value(80),
    ));
    await db.customStatement('DROP TABLE ${db.weeklyPlans.actualTableName}');
    await db.customStatement('DROP TABLE IF EXISTS foods');
    await db.customStatement('DROP TABLE IF EXISTS food_logs');

    // Rewind the ALTER-modified tables to their oldest shapes so the
    // older branches can legitimately re-run (convention from
    // body_metrics_migration_test).
    Future<void> downgrade(String table, String ddl,
        {Set<String> drop = const {}}) async {
      final columnRows = await db.customSelect('PRAGMA table_info($table)').get();
      final names = [for (final r in columnRows) r.data['name'] as String];
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
    await db.customStatement('DROP TABLE body_metrics');

    // from = 1 replays branches v2..v9.
    await db.migration.onUpgrade(Migrator(db), 1, 9);

    // v2: plan table usable again.
    await db.weeklyPlans.insertOnConflictUpdate(WeeklyPlansCompanion.insert(
      weekday: const Value(1),
      routineId: const Value('push-day'),
      updatedAt: DateTime.now(),
    ));
    final plan = await (db.weeklyPlans.select()
          ..where((w) => w.weekday.equals(1)))
        .getSingle();
    expect(plan.routineId, 'push-day');

    // v4: profile columns restored, preserved username/weight survived.
    final profile =
        await (db.profiles.select()..where((p) => p.id.equals('local')))
            .getSingle();
    expect(profile.username, 'Pio');
    expect(profile.bodyweightKg, 80);
    expect(profile.heightCm, isNull);

    // v6: body_metrics recreated, backfilled from the preserved weight.
    final today = await db.bodyMetricOnce(dayKey(DateTime.now()));
    expect(today!.weightKg, 80);

    // v9: the new artifacts exist with the new columns.
    expect(await tableExists('foods'), isTrue);
    expect(await tableExists('food_logs'), isTrue);
    expect(await columns('body_metrics'), containsAll(['water_ml', 'steps']));
  });

  test('the full v9 schema round-trips a food + log out of the box',
      () async {
    await db.into(db.foods).insert(FoodsCompanion.insert(
          id: 'food-1',
          name: 'Whey',
          kcal: const Value(120),
          proteinG: const Value(25),
          carbsG: const Value(3),
          fatG: const Value(1.5),
          updatedAt: DateTime.now(),
        ));
    final food = await (db.foods.select()
          ..where((f) => f.id.equals('food-1')))
        .getSingle();
    expect(food.servingSize, 100);
    expect(food.servingUnit, 'g');
    expect(food.isCustom, true);
    expect(food.ownerId, isNull);
    expect(food.deletedAt, isNull);

    await db.into(db.foodLogs).insert(FoodLogsCompanion.insert(
          id: 'log-1',
          dayKey: '2026-10-17',
          foodId: const Value('food-1'),
          name: food.name,
          servings: const Value(1.5),
          kcal: 180,
          proteinG: 37.5,
          carbsG: 4.5,
          fatG: 2.25,
          loggedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
    final log = await db.foodLogs.select().getSingle();
    expect(log.dayKey, '2026-10-17');
    expect(log.name, 'Whey');
    expect(log.foodId, 'food-1');
    expect(log.servings, 1.5);
    expect(log.deletedAt, isNull); // live row, sync columns present
  });
}
