import 'package:drift/drift.dart';

import '../database/database.dart';
import 'sync_codec.dart';
import 'sync_transport.dart';

/// Outcome of one [SyncEngine.sync] cycle.
class SyncResult {
  const SyncResult({
    required this.startedAt,
    required this.pulled,
    required this.pushed,
  });

  /// Wall-clock time captured BEFORE the pull — persist this as the next
  /// sync cursor. Rows written during the cycle (locally or remotely) land
  /// after it and are picked up by the following sync.
  final DateTime startedAt;

  /// Remote rows applied locally (last-write-wins).
  final int pulled;

  /// Local parent rows uploaded (children ride along).
  final int pushed;
}

/// Offline-first sync: pull-then-push, last-write-wins per row.
///
/// Invariants the write sites maintain (see `WorkoutSessionNotifier._touchWorkout`
/// and `RoutineRepository.saveRoutine`):
///
/// * a parent row's `updatedAt` is bumped by every child mutation, so
///   last-write-wins at the parent level can replace children wholesale —
///   that replacement is also how hard child deletes propagate remotely;
/// * soft deletes bump `updatedAt` too: tombstones are rows with
///   `deleted_at` set, pushed like any other change and never hard-deleted
///   remotely;
/// * pushed rows are marked clean with `synced_at = updatedAt` only where
///   `id AND updatedAt` still match the values we uploaded (a concurrent
///   edit keeps the row dirty for the next cycle).
class SyncEngine {
  SyncEngine({
    required this.db,
    required this.transport,
    required this.recompute,
  });

  final AppDatabase db;
  final SyncTransport transport;

  /// Rebuilds analytics rollup days for the given set-log instants. Called
  /// inside the apply transaction, so data + rollups commit atomically.
  final Future<void> Function(List<DateTime> touchedLogTimes) recompute;

  /// Re-pull window over the stored cursor — rows written concurrently with
  /// the previous cycle can't slip through the gap.
  static const _overlap = Duration(minutes: 15);
  static const _firstSync = Duration(days: 365 * 5); // ≈ 2020-01-01

  Future<SyncResult> sync({DateTime? since}) async {
    final startedAt = DateTime.now().toUtc();
    final cut = since == null
        ? startedAt.subtract(_firstSync)
        : since.toUtc().subtract(_overlap);

    var pulled = 0;
    var pushed = 0;

    // Pull first: last-write-wins resolves conflicts before we upload, and
    // rows the pull just applied are marked clean (no echo push).
    pulled += await _pullProfiles(cut);
    pulled += await _pullExercises(cut);
    pulled += await _pullRoutines(cut);
    pulled += await _pullWorkouts(cut);
    pulled += await _pullBodyMetrics(cut);

    pushed += await _pushProfiles();
    pushed += await _pushExercises();
    pushed += await _pushRoutines();
    pushed += await _pushWorkouts();
    pushed += await _pushBodyMetrics();

    return SyncResult(startedAt: startedAt, pulled: pulled, pushed: pushed);
  }

  // ---------------------------------------------------------------------------
  // Pull
  // ---------------------------------------------------------------------------

  Future<int> _pullProfiles(DateTime cut) async {
    final rows = await transport.fetchChanged('profiles', since: cut);
    var applied = 0;
    for (final raw in rows) {
      final incoming =
          Profile.fromJson(SyncCodec.decode(raw), serializer: SyncCodec.serializer);
      final local = await _profile(incoming.id);
      if (!_accepts(incoming.updatedAt, local?.updatedAt,
          hasLocal: local != null, tombstone: incoming.deletedAt != null)) {
        continue;
      }
      await db.transaction(() async {
        if (await _recheckProfile(incoming)) return;
        await db.profiles.insertOnConflictUpdate(
            incoming.copyWith(syncedAt: Value(incoming.updatedAt)).toCompanion(false));
      });
      applied++;
    }
    return applied;
  }

  Future<int> _pullExercises(DateTime cut) async {
    final rows = await transport.fetchChanged('exercises', since: cut);
    final candidates = <Exercise>[];
    for (final raw in rows) {
      final incoming =
          Exercise.fromJson(SyncCodec.decode(raw), serializer: SyncCodec.serializer);
      final local = await _exercise(incoming.id);
      if (!_accepts(incoming.updatedAt, local?.updatedAt,
          hasLocal: local != null, tombstone: incoming.deletedAt != null)) {
        continue;
      }
      candidates.add(incoming);
    }
    if (candidates.isEmpty) return 0;

    final children = await _fetchChildren(
      'exercise_muscle_map',
      'exercise_id',
      [for (final e in candidates) e.id],
      (json) => ExerciseMuscleMapData.fromJson(json, serializer: SyncCodec.serializer),
    );
    for (final e in candidates) {
      await _applyExercise(e, children[e.id] ?? const []);
    }
    return candidates.length;
  }

  Future<int> _pullRoutines(DateTime cut) async {
    final rows = await transport.fetchChanged('routines', since: cut);
    final candidates = <Routine>[];
    for (final raw in rows) {
      final incoming = Routine.fromJson(
        SyncCodec.decode(raw, userId: 'local'),
        serializer: SyncCodec.serializer,
      );
      final local = await _routine(incoming.id);
      if (!_accepts(incoming.updatedAt, local?.updatedAt,
          hasLocal: local != null, tombstone: incoming.deletedAt != null)) {
        continue;
      }
      candidates.add(incoming);
    }
    if (candidates.isEmpty) return 0;

    final children = await _fetchChildren(
      'routine_exercises',
      'routine_id',
      [for (final r in candidates) r.id],
      (json) => RoutineExercise.fromJson(json, serializer: SyncCodec.serializer),
    );
    for (final r in candidates) {
      await _applyRoutine(r, children[r.id] ?? const []);
    }
    return candidates.length;
  }

  Future<int> _pullWorkouts(DateTime cut) async {
    final rows = await transport.fetchChanged('workouts', since: cut);
    final candidates = <Workout>[];
    for (final raw in rows) {
      final incoming = Workout.fromJson(
        SyncCodec.decode(raw, userId: 'local'),
        serializer: SyncCodec.serializer,
      );
      final local = await _workout(incoming.id);
      if (local == null) {
        // Never import an in-progress session (it is being logged on the
        // device that created it), and skip tombstones for rows we never had.
        if (incoming.status == 'active' || incoming.deletedAt != null) continue;
        candidates.add(incoming);
      } else if (incoming.updatedAt.isAfter(local.updatedAt)) {
        candidates.add(incoming);
      }
    }
    if (candidates.isEmpty) return 0;

    final children = await _fetchChildren(
      'workout_sets',
      'workout_id',
      [for (final w in candidates) w.id],
      (json) => WorkoutSet.fromJson(json, serializer: SyncCodec.serializer),
    );
    for (final w in candidates) {
      await _applyWorkout(w, children[w.id] ?? const []);
    }
    return candidates.length;
  }

  /// Weigh-ins are flat rows keyed by day — plain LWW like profiles.
  Future<int> _pullBodyMetrics(DateTime cut) async {
    final rows = await transport.fetchChanged('body_metrics', since: cut);
    var applied = 0;
    for (final raw in rows) {
      final incoming = BodyMetric.fromJson(
        SyncCodec.decode(raw),
        serializer: SyncCodec.serializer,
      );
      final local = await _bodyMetric(incoming.id);
      if (!_accepts(incoming.updatedAt, local?.updatedAt,
          hasLocal: local != null, tombstone: incoming.deletedAt != null)) {
        continue;
      }
      await db.bodyMetrics.insertOnConflictUpdate(
          incoming.copyWith(syncedAt: Value(incoming.updatedAt)).toCompanion(false));
      applied++;
    }
    return applied;
  }

  /// Last-write-wins gate, shared by the non-workout pulls.
  bool _accepts(
    DateTime incoming,
    DateTime? local, {
    required bool hasLocal,
    required bool tombstone,
  }) {
    if (!hasLocal) {
      // A tombstone for a row we never had carries no information.
      return !tombstone;
    }
    return incoming.isAfter(local!);
  }

  /// Returns true (→ roll the transaction back) when a concurrent local edit
  /// won the race between candidate selection and this apply.
  Future<bool> _recheckProfile(Profile incoming) async {
    final local = await _profile(incoming.id);
    return local != null && !incoming.updatedAt.isAfter(local.updatedAt);
  }

  Future<void> _applyExercise(
    Exercise incoming,
    List<ExerciseMuscleMapData> remoteMap,
  ) async {
    await db.transaction(() async {
      final local = await _exercise(incoming.id);
      if (local != null && !incoming.updatedAt.isAfter(local.updatedAt)) return;

      // A muscle-mapping change re-credits volume for every day this
      // exercise contributed to.
      final setRows = await (db.workoutSets.select()
            ..where((s) =>
                s.exerciseId.equals(incoming.id) & s.loggedAt.isNotNull()))
          .get();
      final touched = [for (final s in setRows) s.loggedAt!];

      await (db.exerciseMuscleMap.delete()
            ..where((m) => m.exerciseId.equals(incoming.id)))
          .go();
      for (final m in remoteMap) {
        await db.exerciseMuscleMap
            .insertOnConflictUpdate(m.toCompanion(false));
      }
      await db.exercises.insertOnConflictUpdate(
          incoming.copyWith(syncedAt: Value(incoming.updatedAt)).toCompanion(false));
      if (touched.isNotEmpty) await recompute(touched);
    });
  }

  Future<void> _applyRoutine(
    Routine incoming,
    List<RoutineExercise> remoteChildren,
  ) async {
    await db.transaction(() async {
      final local = await _routine(incoming.id);
      if (local != null && !incoming.updatedAt.isAfter(local.updatedAt)) return;

      await (db.routineExercises.delete()
            ..where((e) => e.routineId.equals(incoming.id)))
          .go();
      for (final c in remoteChildren) {
        await db.routineExercises.insertOnConflictUpdate(
            c.copyWith(syncedAt: Value(c.updatedAt)).toCompanion(false));
      }
      await db.routines.insertOnConflictUpdate(
          incoming.copyWith(syncedAt: Value(incoming.updatedAt)).toCompanion(false));
    });
  }

  Future<void> _applyWorkout(
    Workout incoming,
    List<WorkoutSet> remoteSets,
  ) async {
    await db.transaction(() async {
      final local = await _workout(incoming.id);
      if (local != null && !incoming.updatedAt.isAfter(local.updatedAt)) return;

      final localSets = await (db.workoutSets.select()
            ..where((s) => s.workoutId.equals(incoming.id)))
          .get();
      final touched = <DateTime>[
        for (final s in [...localSets, ...remoteSets])
          if (s.loggedAt != null) s.loggedAt!,
      ];

      await (db.workoutSets.delete()
            ..where((s) => s.workoutId.equals(incoming.id)))
          .go();
      for (final s in remoteSets) {
        await db.workoutSets.insertOnConflictUpdate(
            s.copyWith(syncedAt: Value(s.updatedAt)).toCompanion(false));
      }
      await db.workouts.insertOnConflictUpdate(
          incoming.copyWith(syncedAt: Value(incoming.updatedAt)).toCompanion(false));
      if (touched.isNotEmpty) await recompute(touched);
    });
  }

  Future<Map<String, List<T>>> _fetchChildren<T>(
    String table,
    String parentColumn,
    List<String> parentIds,
    T Function(Map<String, dynamic> json) decodeRow,
  ) async {
    if (parentIds.isEmpty) return const {};
    final rows = await transport.fetchChildren(table, parentColumn, parentIds);
    final out = <String, List<T>>{};
    for (final raw in rows) {
      final parentId = raw[parentColumn] as String?;
      if (parentId == null) continue;
      (out[parentId] ??= <T>[]).add(decodeRow(SyncCodec.decode(raw)));
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // Push — dirty scan, children ride parents, tombstones included
  // ---------------------------------------------------------------------------

  Future<int> _pushProfiles() async {
    final dirty = await (db.profiles.select()
          ..where((p) => p.syncedAt.isNull() | p.updatedAt.isBiggerThan(p.syncedAt)))
        .get();
    if (dirty.isEmpty) return 0;
    await transport.upsert('profiles', [
      for (final p in dirty)
        SyncCodec.encode(p.toJson(serializer: SyncCodec.serializer)),
    ]);
    for (final p in dirty) {
      await (db.update(db.profiles)
            ..where((t) => t.id.equals(p.id) & t.updatedAt.equals(p.updatedAt)))
          .write(ProfilesCompanion(syncedAt: Value(p.updatedAt)));
    }
    return dirty.length;
  }

  Future<int> _pushExercises() async {
    final dirty = await (db.exercises.select()
          ..where((e) => e.syncedAt.isNull() | e.updatedAt.isBiggerThan(e.syncedAt)))
        .get();
    if (dirty.isEmpty) return 0;
    final ids = [for (final e in dirty) e.id];
    final mapRows = await (db.exerciseMuscleMap.select()
          ..where((m) => m.exerciseId.isIn(ids)))
        .get();

    await transport.upsert('exercises', [
      for (final e in dirty)
        SyncCodec.encode(e.toJson(serializer: SyncCodec.serializer)),
    ]);
    try {
      await transport.replaceChildren(
        'exercise_muscle_map',
        'exercise_id',
        ids,
        [
          for (final m in mapRows)
            SyncCodec.encode(m.toJson(serializer: SyncCodec.serializer)),
        ],
      );
    } catch (_) {
      // Parents are already remote; bump them so the retry pushes a newer
      // updatedAt and other devices refetch children against it.
      await _touchExercises(ids, _bumpTime([for (final e in dirty) e.updatedAt]));
      rethrow;
    }
    for (final e in dirty) {
      await (db.update(db.exercises)
            ..where((t) => t.id.equals(e.id) & t.updatedAt.equals(e.updatedAt)))
          .write(ExercisesCompanion(syncedAt: Value(e.updatedAt)));
    }
    return dirty.length;
  }

  Future<int> _pushRoutines() async {
    final dirtyParents = await (db.routines.select()
          ..where((r) => r.syncedAt.isNull() | r.updatedAt.isBiggerThan(r.syncedAt)))
        .get();
    final dirtyChildren = await (db.routineExercises.select()
          ..where((e) => e.syncedAt.isNull() | e.updatedAt.isBiggerThan(e.syncedAt)))
        .get();
    final ids = <String>{
      for (final r in dirtyParents) r.id,
      for (final c in dirtyChildren) c.routineId,
    };
    if (ids.isEmpty) return 0;
    final idList = ids.toList();
    final parents = await (db.routines.select()
          ..where((r) => r.id.isIn(idList)))
        .get();
    final children = await (db.routineExercises.select()
          ..where((e) => e.routineId.isIn(idList)))
        .get();

    await transport.upsert('routines', [
      for (final r in parents)
        SyncCodec.encode(r.toJson(serializer: SyncCodec.serializer)),
    ]);
    try {
      await transport.replaceChildren(
        'routine_exercises',
        'routine_id',
        idList,
        [
          for (final c in children)
            SyncCodec.encode(c.toJson(serializer: SyncCodec.serializer)),
        ],
      );
    } catch (_) {
      await _touchRoutines(idList, _bumpTime([for (final r in parents) r.updatedAt]));
      rethrow;
    }
    for (final r in parents) {
      await (db.update(db.routines)
            ..where((t) => t.id.equals(r.id) & t.updatedAt.equals(r.updatedAt)))
          .write(RoutinesCompanion(syncedAt: Value(r.updatedAt)));
    }
    for (final c in dirtyChildren) {
      await (db.update(db.routineExercises)
            ..where((t) => t.id.equals(c.id) & t.updatedAt.equals(c.updatedAt)))
          .write(RoutineExercisesCompanion(syncedAt: Value(c.updatedAt)));
    }
    return parents.length;
  }

  Future<int> _pushWorkouts() async {
    final dirtyParents = await (db.workouts.select()
          ..where((w) => w.syncedAt.isNull() | w.updatedAt.isBiggerThan(w.syncedAt)))
        .get();
    final dirtySets = await (db.workoutSets.select()
          ..where((s) => s.syncedAt.isNull() | s.updatedAt.isBiggerThan(s.syncedAt)))
        .get();
    final ids = <String>{
      for (final w in dirtyParents) w.id,
      for (final s in dirtySets) s.workoutId,
    };
    if (ids.isEmpty) return 0;
    final idList = ids.toList();
    final parents = await (db.workouts.select()
          ..where((w) => w.id.isIn(idList)))
        .get();
    final children = await (db.workoutSets.select()
          ..where((s) => s.workoutId.isIn(idList)))
        .get();

    await transport.upsert('workouts', [
      for (final w in parents)
        SyncCodec.encode(w.toJson(serializer: SyncCodec.serializer)),
    ]);
    try {
      await transport.replaceChildren(
        'workout_sets',
        'workout_id',
        idList,
        [
          for (final s in children)
            SyncCodec.encode(s.toJson(serializer: SyncCodec.serializer)),
        ],
      );
    } catch (_) {
      await _touchWorkouts(idList, _bumpTime([for (final w in parents) w.updatedAt]));
      rethrow;
    }
    for (final w in parents) {
      await (db.update(db.workouts)
            ..where((t) => t.id.equals(w.id) & t.updatedAt.equals(w.updatedAt)))
          .write(WorkoutsCompanion(syncedAt: Value(w.updatedAt)));
    }
    for (final s in dirtySets) {
      await (db.update(db.workoutSets)
            ..where((t) => t.id.equals(s.id) & t.updatedAt.equals(s.updatedAt)))
          .write(WorkoutSetsCompanion(syncedAt: Value(s.updatedAt)));
    }
    return parents.length;
  }

  Future<int> _pushBodyMetrics() async {
    final dirty = await (db.bodyMetrics.select()
          ..where((m) =>
              m.syncedAt.isNull() | m.updatedAt.isBiggerThan(m.syncedAt)))
        .get();
    if (dirty.isEmpty) return 0;
    await transport.upsert('body_metrics', [
      for (final m in dirty)
        SyncCodec.encode(m.toJson(serializer: SyncCodec.serializer)),
    ]);
    for (final m in dirty) {
      await (db.update(db.bodyMetrics)
            ..where((t) => t.id.equals(m.id) & t.updatedAt.equals(m.updatedAt)))
          .write(BodyMetricsCompanion(syncedAt: Value(m.updatedAt)));
    }
    return dirty.length;
  }

  /// `updatedAt` for a retry bump: strictly newer than every row we just
  /// tried to push, even if the device clock sits behind them.
  static DateTime _bumpTime(Iterable<DateTime> stamps) {
    var t = DateTime.now();
    for (final s in stamps) {
      final bumped = s.add(const Duration(seconds: 1));
      if (bumped.isAfter(t)) t = bumped;
    }
    return t;
  }

  Future<void> _touchExercises(List<String> ids, DateTime bumpTo) =>
      (db.update(db.exercises)..where((e) => e.id.isIn(ids)))
          .write(ExercisesCompanion(updatedAt: Value(bumpTo)));

  Future<void> _touchRoutines(List<String> ids, DateTime bumpTo) =>
      (db.update(db.routines)..where((r) => r.id.isIn(ids)))
          .write(RoutinesCompanion(updatedAt: Value(bumpTo)));

  Future<void> _touchWorkouts(List<String> ids, DateTime bumpTo) =>
      (db.update(db.workouts)..where((w) => w.id.isIn(ids)))
          .write(WorkoutsCompanion(updatedAt: Value(bumpTo)));

  // ---------------------------------------------------------------------------
  // Point reads
  // ---------------------------------------------------------------------------

  Future<Profile?> _profile(String id) =>
      (db.profiles.select()..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<Exercise?> _exercise(String id) =>
      (db.exercises.select()..where((e) => e.id.equals(id))).getSingleOrNull();

  Future<Routine?> _routine(String id) =>
      (db.routines.select()..where((r) => r.id.equals(id))).getSingleOrNull();

  Future<Workout?> _workout(String id) =>
      (db.workouts.select()..where((w) => w.id.equals(id))).getSingleOrNull();

  Future<BodyMetric?> _bodyMetric(String id) =>
      (db.bodyMetrics.select()..where((m) => m.id.equals(id)))
          .getSingleOrNull();
}
