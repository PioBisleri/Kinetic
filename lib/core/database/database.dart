import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

// ------------------------------ profile -----------------------------------

class Profiles extends Table with SyncColumns {
  TextColumn get id => text()(); // = auth.uid()
  TextColumn get username => text().nullable()();
  TextColumn get unitSystem => text().withDefault(const Constant('kg'))();
  TextColumn get theme => text().withDefault(const Constant('dark'))();
  RealColumn get bodyweightKg => real().nullable()();

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
  IntColumn get restSeconds => integer().withDefault(const Constant(90))();
  BoolColumn get isWarmup => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
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
  MuscleGroups,
  Exercises,
  ExerciseMuscleMap,
  Routines,
  RoutineExercises,
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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Future migrations go here; never edit schemaVersion in place
          // without adding a branch.
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await customStatement('PRAGMA journal_mode = WAL');
          await customStatement('PRAGMA synchronous = NORMAL');
        },
      );

  // ------------------------- query helpers --------------------------------

  Stream<List<Exercise>> watchExercises({String? category, String? search}) {
    final query = select(exercises)
      ..where((e) => e.deletedAt.isNull())
      ..orderBy([(e) => OrderingTerm.asc(e.name)]);
    if (category != null) {
      query.where((e) => e.category.equals(category));
    }
    if (search != null && search.isNotEmpty) {
      query.where((e) => e.name.lower().like('%${search.toLowerCase()}%'));
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
  Stream<int> exerciseCount() => customSelect(
        'SELECT COUNT(*) AS c FROM exercises WHERE deleted_at IS NULL',
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
