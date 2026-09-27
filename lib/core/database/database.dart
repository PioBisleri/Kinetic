import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/day_key.dart';

part 'database.g.dart';

// ---------------------------------------------------------------------------
// Shared sync columns — every user-owned or catalog table carries these so the
// offline outbox + last-write-wins sync engine can work uniformly.
// ---------------------------------------------------------------------------

mixin SyncColumns on Table {
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // tombstone
}

/// [RoutineExercises.restSeconds] value meaning "no routine override": fall
/// through to [Exercises.restSeconds], then to the per-type Settings default.
///
/// A sentinel rather than NULL because SQLite can only add columns (not make
/// them nullable) with `ALTER TABLE`, and this column predates v3.
const inheritRestSeconds = -1;

// ------------------------------ profile -----------------------------------

class Profiles extends Table with SyncColumns {
  TextColumn get id => text()(); // = auth.uid()
  TextColumn get username => text().nullable()();
  TextColumn get unitSystem => text().withDefault(const Constant('kg'))();
  TextColumn get theme => text().withDefault(const Constant('dark'))();
  RealColumn get bodyweightKg => real().nullable()();

  // "Your data" (Round 5 / v4) — all nullable, display-only inputs.
  // Canonical storage: height in cm, birth date as ISO yyyy-MM-dd,
  // sex in {female, male, other}, goal in {strength, hypertrophy,
  // general}. Body fat is a percentage.
  RealColumn get heightCm => real().nullable()();
  TextColumn get birthDate => text().nullable()();
  TextColumn get sex => text().nullable()();
  RealColumn get bodyFatPct => real().nullable()();
  TextColumn get trainingGoal => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// --------------------------- body metrics ---------------------------------

/// One weigh-in per local calendar day (Round 6 / v6): the trend's data
/// points. Keyed by `dayKey` ('2026-09-27'), so re-weighing today
/// updates the row in place — locally and, via LWW, remotely.
class BodyMetrics extends Table with SyncColumns {
  TextColumn get id => text()(); // local day key
  RealColumn get weightKg => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// --------------------------- muscle groups --------------------------------

class MuscleGroups extends Table with SyncColumns {
  TextColumn get id => text()(); // 'chest', 'front_delts', ...
  TextColumn get parentId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get heatmapNodes => text().withDefault(const Constant('[]'))();
  // JSON array, e.g. ["front.chest_l","front.chest_r"]
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ------------------------------ exercises ---------------------------------

class Exercises extends Table with SyncColumns {
  TextColumn get id => text()(); // slug, client-generated
  TextColumn get name => text()();
  TextColumn get mechanics => text()(); // compound | isolation
  TextColumn get forceType => text().nullable()(); // push | pull | static
  TextColumn get category =>
      text().withDefault(const Constant('barbell'))();
  TextColumn get primaryMuscleId => text()();
  TextColumn get equipment =>
      text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get defaultMetric =>
      text().withDefault(const Constant('weight_reps'))();
  TextColumn get animationKind =>
      text().withDefault(const Constant('none'))();
  TextColumn get animationRef => text().nullable()();
  TextColumn get thumbnailRef => text().nullable()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  TextColumn get ownerId => text().nullable()(); // null = global seeded row

  /// Rest between sets of this exercise in seconds; null = inherit the
  /// Settings default for the set type.
  IntColumn get restSeconds => integer().nullable()();

  /// Progression step for this exercise in kg; null = inherit the unit
  /// default (2.5 kg / 5 lb). Canonical kg, like every other weight.
  RealColumn get progressionIncrementKg => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ExerciseMuscleMap extends Table {
  TextColumn get exerciseId => text()();
  TextColumn get muscleId => text()();

  /// 0..1 — share of stimulus credited to this muscle (bench: chest 1.0,
  /// triceps 0.5). Drives volume attribution and the Muscle Grade engine.
  RealColumn get contribution => real().withDefault(const Constant(1.0))();
  TextColumn get role => text().withDefault(const Constant('secondary'))();

  @override
  Set<Column> get primaryKey => {exerciseId, muscleId};
}

// ------------------------------- routines ---------------------------------

class Routines extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class RoutineExercises extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get routineId => text()();
  TextColumn get exerciseId => text()();
  IntColumn get orderIndex => integer()();
  IntColumn get supersetGroup => integer().nullable()();
  IntColumn get targetSets => integer().withDefault(const Constant(3))();
  IntColumn get targetReps => integer().withDefault(const Constant(8))();
  RealColumn get targetRpe => real().nullable()();
  RealColumn get targetWeight => real().nullable()();

  /// Rest after each set of this entry in seconds.
  /// [inheritRestSeconds] = -1 → fall through to the exercise override,
  /// then to the per-type Settings default. (Kept NOT NULL so the column
  /// can be added by `ALTER TABLE` without a table rebuild.)
  IntColumn get restSeconds => integer().withDefault(const Constant(90))();

  /// Per-type planned set counts (Hevy-style). `targetSets` stays the
  /// TOTAL planned sets; working = targetSets − warmup − drop − failure.
  IntColumn get warmupSets => integer().withDefault(const Constant(0))();
  IntColumn get dropSets => integer().withDefault(const Constant(0))();
  IntColumn get failureSets => integer().withDefault(const Constant(0))();

  /// Legacy v1/v2 flag: the whole entry was warm-up. Kept for wire
  /// compatibility; derived from [warmupSets] on write since v3.
  BoolColumn get isWarmup => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ----------------------------- weekly plan --------------------------------

/// The view-only weekly plan: at most one routine per weekday (1 = Mon …
/// 7 = Sun); a null/absent row means rest day. Purely a planning surface —
/// it never schedules notifications.
class WeeklyPlans extends Table with SyncColumns {
  IntColumn get weekday => integer()();
  TextColumn get routineId => text().nullable()();

  @override
  Set<Column> get primaryKey => {weekday};
}

// ---------------------------- live workout --------------------------------

class Workouts extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get routineId => text().nullable()();
  TextColumn get status =>
      text().withDefault(const Constant('active'))(); // active|completed|abandoned
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get durationSec => integer().nullable()();
  RealColumn get totalVolume => real().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class WorkoutSets extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get workoutId => text()();
  TextColumn get exerciseId => text()();
  IntColumn get orderIndex => integer()();

  TextColumn get setType =>
      text().withDefault(const Constant('working'))();
  // warmup | working | drop | failure | cardio
  IntColumn get supersetGroup => integer().nullable()();
  RealColumn get weightKg => real().nullable()(); // ALWAYS stored in kg
  IntColumn get reps => integer().nullable()();
  RealColumn get rpe => real().nullable()();
  RealColumn get distanceM => real().nullable()();
  IntColumn get durationSec => integer().nullable()();
  IntColumn get heartRate => integer().nullable()();
  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get loggedAt => dateTime().nullable()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// --------------------------- analytics rollups ----------------------------

class MuscleVolumeDaily extends Table {
  TextColumn get userId => text()();
  TextColumn get muscleId => text()();
  DateTimeColumn get date => dateTime()();
  IntColumn get totalSets => integer().withDefault(const Constant(0))();
  RealColumn get volume => real().withDefault(const Constant(0))();
  RealColumn get bestE1Rm => real().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {userId, muscleId, date};
}

class ExerciseHistory extends Table {
  TextColumn get userId => text()();
  TextColumn get exerciseId => text()();
  DateTimeColumn get date => dateTime()();
  RealColumn get bestE1Rm => real().withDefault(const Constant(0))();
  RealColumn get topWeight => real().withDefault(const Constant(0))();
  IntColumn get topReps => integer().withDefault(const Constant(0))();
  RealColumn get totalVolume => real().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {userId, exerciseId, date};
}

class MuscleGradeHistory extends Table {
  TextColumn get userId => text()();
  TextColumn get muscleId => text()();
  DateTimeColumn get computedAt => dateTime()();
  TextColumn get grade => text()(); // F D C B A S
  RealColumn get score => real()(); // 0..100
  RealColumn get volumeComponent => real()();
  RealColumn get strengthComponent => real()();
  RealColumn get consistencyComponent => real()();

  @override
  Set<Column> get primaryKey => {userId, muscleId, computedAt};
}

// ------------------------------ offline outbox ----------------------------

class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Target drift table name. (Named [targetTable], not `tableName` —
  /// that collides with Drift's built-in `Table.tableName` getter.)
  TextColumn get targetTable => text()();
  TextColumn get rowId => text()();
  TextColumn get op => text()(); // upsert | delete
  TextColumn get payload => text()(); // JSON
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retries => integer().withDefault(const Constant(0))();
}

// -------------------------------- database --------------------------------

@DriftDatabase(tables: [
  Profiles,
  BodyMetrics,
  MuscleGroups,
  Exercises,
  ExerciseMuscleMap,
  Routines,
  RoutineExercises,
  WeeklyPlans,
  Workouts,
  WorkoutSets,
  MuscleVolumeDaily,
  ExerciseHistory,
  MuscleGradeHistory,
  SyncQueue,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'kinetic'));

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
        onUpgrade: (m, from, to) async {
          // v2: the view-only weekly plan (Round 2). Never edit
          // schemaVersion in place without adding a branch. Each branch
          // gates on `to` as well as `from`, so a step that upgrades only
          // as far as N (as the Round 2 migration test does) doesn't run
          // the later branches against a schema that lacks them yet.
          if (from < 2 && to >= 2) await m.createTable(weeklyPlans);

          // v3: custom rest + per-type planned set counts. `restSeconds`
          // already exists on routine_exercises, so it only needs its
          // placeholder rewritten; the count columns are new.
          if (from < 3 && to >= 3) {
            await m.addColumn(exercises, exercises.restSeconds);
            await m.addColumn(routineExercises, routineExercises.warmupSets);
            await m.addColumn(routineExercises, routineExercises.dropSets);
            await m.addColumn(routineExercises, routineExercises.failureSets);
            // The stored 90 was never user-editable — it predates any UI.
            // -1 marks "inherit exercise → Settings".
            await customStatement(
                'UPDATE routine_exercises SET rest_seconds = -1');
            // Backfill: a v1/v2 warm-up entry meant ALL its sets were
            // warm-up.
            await customStatement(
                'UPDATE routine_exercises SET warmup_sets = target_sets '
                'WHERE is_warmup = 1');
          }

          // v4: "Your data" profile fields (Round 5). Every column is
          // nullable, so this is five plain ADD COLUMNs — no rebuild, no
          // backfill; existing rows simply read NULL until filled in.
          if (from < 4 && to >= 4) {
            await m.addColumn(profiles, profiles.heightCm);
            await m.addColumn(profiles, profiles.birthDate);
            await m.addColumn(profiles, profiles.sex);
            await m.addColumn(profiles, profiles.bodyFatPct);
            await m.addColumn(profiles, profiles.trainingGoal);
          }

          // v5: per-exercise progression increment (Round 6). Nullable —
          // NULL means "follow the unit default" — so a single ADD COLUMN
          // with no backfill; every seeded and custom exercise simply
          // keeps behaving like before until overridden.
          if (from < 5 && to >= 5) {
            await m.addColumn(
                exercises, exercises.progressionIncrementKg);
          }

          // v6: bodyweight trend (Round 6). A fresh table plus one
          // backfill: upgrading users' current profile weight becomes
          // today's first point (real value, real date — nothing is
          // invented for past days).
          if (from < 6 && to >= 6) {
            await m.createTable(bodyMetrics);
            await customStatement(
              'INSERT OR IGNORE INTO body_metrics '
              '(id, weight_kg, updated_at) '
              'SELECT ?, bodyweight_kg, ? '
              'FROM profiles WHERE id = ? AND bodyweight_kg IS NOT NULL',
              [
                dayKey(DateTime.now()),
                DateTime.now().toUtc().millisecondsSinceEpoch,
                'local',
              ],
            );
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await customStatement('PRAGMA journal_mode = WAL');
          await customStatement('PRAGMA synchronous = NORMAL');
        },
      );

  // ------------------------- query helpers --------------------------------

  /// Watch the catalog (optionally within one category), name-ordered.
  ///
  /// Search is deliberately *not* a SQL concern: ranking (typos, synonyms,
  /// muscle matches) happens client-side — see core/search/smart_search.dart.
  Stream<List<Exercise>> watchExercises({String? category}) {
    final query = select(exercises)
      ..where((e) => e.deletedAt.isNull())
      ..orderBy([(e) => OrderingTerm.asc(e.name)]);
    if (category != null) {
      query.where((e) => e.category.equals(category));
    }
    return query.watch();
  }

  Stream<Workout?> watchActiveWorkout() {
    final query = select(workouts)
      ..where((w) => w.status.equals('active'))
      ..orderBy([(w) => OrderingTerm.desc(w.startedAt)])
      ..limit(1);
    return query.watchSingleOrNull();
  }

  /// Cheap COUNT(*) over the exercise catalog (avoids loading all rows).
  ///
  /// `readsFrom` is essential: drift can't parse the SQL, so without it
  /// the stream never re-emits when an exercise is inserted (the header
  /// counter stayed stale until something else poked the query).
  Stream<int> exerciseCount() => customSelect(
        'SELECT COUNT(*) AS c FROM exercises WHERE deleted_at IS NULL',
        readsFrom: {exercises},
      ).map((row) => row.read<int>('c')).watchSingle();

  /// One-shot count for tests/one-off reads — a stream subscription that
  /// gets cancelled mid-test leaves a pending close-timer in flutter_test.
  Future<int> exerciseCountOnce() => customSelect(
        'SELECT COUNT(*) AS c FROM exercises WHERE deleted_at IS NULL',
      ).map((row) => row.read<int>('c')).getSingle();

  Future<List<WorkoutSet>> setsForWorkout(String workoutId) {
    final query = select(workoutSets)
      ..where((s) => s.workoutId.equals(workoutId))
      ..orderBy([(s) => OrderingTerm.asc(s.orderIndex)]);
    return query.get();
  }
}

final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('overridden in main()'),
);
