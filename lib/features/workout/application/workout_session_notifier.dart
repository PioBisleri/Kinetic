import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database.dart';
import '../../../core/notifications/rest_notification_service.dart';
import '../../../core/settings/settings.dart';
import '../../analytics/application/rollup_service.dart';
import '../../analytics/domain/analytics_math.dart';
import '../../home/home_screen_widget.dart';

/// The in-memory view of the workout currently being logged.
class WorkoutSession {
  const WorkoutSession({
    required this.workout,
    required this.exercises,
    required this.sets,
    required this.supersetGroups,
  });

  final Workout workout;
  final List<Exercise> exercises; // insertion order (sets + setless adds)
  final List<WorkoutSet> sets; // ordered by orderIndex
  final Map<String, int> supersetGroups; // exerciseId → group

  List<WorkoutSet> setsFor(String exerciseId) =>
      sets.where((s) => s.exerciseId == exerciseId).toList();

  int get completedSetCount => sets.where((s) => s.isCompleted).length;

  double get volumeKg => sets
      .where((s) => hardSetTypes.contains(s.setType) && s.isCompleted)
      .fold(0.0, (a, s) => a + (s.weightKg ?? 0) * (s.reps ?? 0));

  Duration get elapsed =>
      (workout.endedAt ?? DateTime.now()).difference(workout.startedAt);

  int? supersetGroupOf(String exerciseId) => supersetGroups[exerciseId];
}

/// Owns the live workout session: every mutation lands in SQLite first
/// (crash- and airplane-safe), then invalidates this provider so the UI —
/// which only ever reads state — stays in sync.
final workoutSessionProvider =
    AsyncNotifierProvider<WorkoutSessionNotifier, WorkoutSession?>(
        WorkoutSessionNotifier.new);

class WorkoutSessionNotifier extends AsyncNotifier<WorkoutSession?> {
  AppDatabase get _db => ref.read(databaseProvider);
  static const _uuid = Uuid();

  /// Analytics rollups are rebuilt for every day a set mutation touches.
  RollupService get _rollups => RollupService(_db);

  /// Sync invariant (Phase 7): set mutations bump the parent workout so
  /// `workout.updatedAt` ≥ any child edit. Sync then pushes children by
  /// replacing the parent's whole set, so last-write-wins at the workout
  /// level is always safe — and a hard set delete propagates with it.
  Future<void> _touchWorkout(String workoutId, DateTime now) =>
      (_db.workouts.update()..where((w) => w.id.equals(workoutId)))
          .write(WorkoutsCompanion(updatedAt: Value(now)));

  /// Session-lifetime overlays for rows that exist only logically:
  /// - exercises added but not yet given a set (no durable row exists)
  /// - superset groups for exercises without a set yet
  /// Both are rebuilt from durable data when sets exist.
  final Map<String, int> _addedExerciseOrder = {};
  final Map<String, int> _pendingSupersetGroups = {};

  @override
  Future<WorkoutSession?> build() async {
    final workout = await (_db.workouts.select()
          ..where((w) => w.status.equals('active'))
          ..orderBy([(w) => OrderingTerm.desc(w.startedAt)])
          ..limit(1))
        .getSingleOrNull();
    if (workout == null) {
      _addedExerciseOrder.clear();
      _pendingSupersetGroups.clear();
      return null;
    }

    final sets = await (_db.workoutSets.select()
          ..where((s) => s.workoutId.equals(workout.id))
          ..orderBy([(s) => OrderingTerm.asc(s.orderIndex)]))
        .get();

    // Exercises with sets, in first-appearance order.
    final ids = <String>[];
    for (final s in sets) {
      if (!ids.contains(s.exerciseId)) ids.add(s.exerciseId);
    }

    // Append setless exercises (added but never logged), by add order.
    final setless = _addedExerciseOrder.keys
        .where((id) => !ids.contains(id))
        .toList()
      ..sort((a, b) =>
          (_addedExerciseOrder[a] ?? 0).compareTo(_addedExerciseOrder[b] ?? 0));
    ids.addAll(setless);

    final exercises = <Exercise>[];
    for (final id in ids) {
      final e = await (_db.exercises.select()
            ..where((x) => x.id.equals(id))
            ..limit(1))
          .getSingleOrNull();
      if (e != null) exercises.add(e);
    }

    // Superset groups: durable per-set values win over in-memory links.
    final groups = Map<String, int>.from(_pendingSupersetGroups);
    for (final s in sets) {
      final g = s.supersetGroup;
      if (g != null) groups[s.exerciseId] = g;
    }

    return WorkoutSession(
      workout: workout,
      exercises: exercises,
      sets: sets,
      supersetGroups: groups,
    );
  }

  void _requireActive() {
    if (state.value == null) {
      throw StateError('No active workout');
    }
  }

  // ----------------------------- session lifecycle -----------------------

  Future<void> startWorkout({String? routineId}) async {
    // Only ever one active workout.
    final active = await (_db.workouts.select()
          ..where((w) => w.status.equals('active'))
          ..limit(1))
        .getSingleOrNull();
    if (active != null) return;

    final now = DateTime.now();
    final workoutId = _uuid.v4();
    await _db.workouts.insertOnConflictUpdate(WorkoutsCompanion.insert(
      id: workoutId,
      userId: 'local', // real uid injected by auth in Phase 7
      startedAt: now,
      updatedAt: now,
      routineId: Value(routineId),
    ));

    // Seed planned (uncompleted) sets from the routine's targets.
    if (routineId != null) {
      final planned = await (_db.routineExercises.select()
            ..where((e) =>
                e.routineId.equals(routineId) & e.deletedAt.isNull())
            ..orderBy([(e) => OrderingTerm.asc(e.orderIndex)]))
          .get();
      if (planned.isNotEmpty) {
        var order = 0;
        await _db.batch((b) {
          for (final e in planned) {
            // Hevy-style: warm-up first, then working, drop, failure.
            final working = (e.targetSets -
                    e.warmupSets -
                    e.dropSets -
                    e.failureSets)
                .clamp(0, e.targetSets);
            final typed = <(String, int)>[
              ('warmup', e.warmupSets),
              ('working', working),
              ('drop', e.dropSets),
              ('failure', e.failureSets),
            ];
            for (final (type, count) in typed) {
              for (var i = 0; i < count; i++) {
                b.insert(_db.workoutSets, WorkoutSetsCompanion.insert(
                  id: _uuid.v4(),
                  workoutId: workoutId,
                  exerciseId: e.exerciseId,
                  orderIndex: order++,
                  setType: Value(type),
                  supersetGroup: Value(e.supersetGroup),
                  weightKg: Value(e.targetWeight),
                  reps: Value(e.targetReps),
                  rpe: Value(e.targetRpe),
                  isCompleted: const Value(false),
                  updatedAt: now,
                ));
              }
            }
          }
        });
      }
    }

    ref.invalidateSelf();
    await future;
  }

  Future<void> finishWorkout({String? notes}) async {
    _requireActive();
    final session = state.value!;
    final now = DateTime.now();
    await (_db.workouts.update()
          ..where((w) => w.id.equals(session.workout.id)))
        .write(WorkoutsCompanion(
      status: const Value('completed'),
      endedAt: Value(now),
      durationSec: Value(now.difference(session.workout.startedAt).inSeconds),
      totalVolume: Value(session.volumeKg),
      notes: notes != null ? Value(notes) : const Value.absent(),
      updatedAt: Value(now),
    ));
    _addedExerciseOrder.clear();
    _pendingSupersetGroups.clear();
    ref.read(restTimerProvider.notifier).reset();
    ref.invalidateSelf();
    await future;
    // Fresh numbers on the home-screen widget (best-effort, non-blocking).
    // Guarded: tests may run without a SharedPreferences override, and the
    // widget is cosmetic — never let it fail a workout finish.
    try {
      unawaited(updateHomeScreenWidget(_db, ref.read(settingsProvider).unit));
    } catch (_) {}
  }

  /// Throw the whole session away without saving it to history: hard-delete
  /// the workout and every set logged in it, then rebuild the rollups for
  /// any day an already-completed set had touched (they no longer count).
  /// No-op when there is no active workout.
  ///
  /// Reads the workout and its sets fresh from SQLite rather than trusting
  /// `state` — `logSet` invalidates lazily, so the cached session can still
  /// be missing the sets we need to unwind.
  Future<void> discardWorkout() async {
    final workout = await (_db.workouts.select()
          ..where((w) => w.status.equals('active'))
          ..orderBy([(w) => OrderingTerm.desc(w.startedAt)])
          ..limit(1))
        .getSingleOrNull();
    if (workout == null) return;

    final sets = await (_db.workoutSets.select()
          ..where((s) => s.workoutId.equals(workout.id)))
        .get();
    final days = <DateTime>{
      for (final s in sets)
        if (s.isCompleted && s.loggedAt != null) dayOf(s.loggedAt!),
    };
    await (_db.workoutSets.delete()
          ..where((s) => s.workoutId.equals(workout.id)))
        .go();
    await (_db.workouts.delete()..where((w) => w.id.equals(workout.id)))
        .go();
    for (final d in days) {
      await _rollups.recomputeDay(d);
    }
    _addedExerciseOrder.clear();
    _pendingSupersetGroups.clear();
    ref.read(restTimerProvider.notifier).reset();
    ref.invalidateSelf();
    await future;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  // ------------------------------ exercises ------------------------------

  Future<void> addExercise(String exerciseId) async {
    _requireActive();
    final session = state.value!;
    if (session.exercises.any((e) => e.id == exerciseId)) return;
    final exists =
        await (_db.exercises.select()..where((e) => e.id.equals(exerciseId)))
            .getSingleOrNull();
    if (exists == null) return;
    final nextOrder = session.exercises.length;
    _addedExerciseOrder[exerciseId] = nextOrder;
    ref.invalidateSelf();
    await future;
  }

  Future<void> removeExercise(String exerciseId) async {
    _requireActive();
    final session = state.value!;
    final rows = await (_db.workoutSets.select()
          ..where((s) =>
              s.workoutId.equals(session.workout.id) &
              s.exerciseId.equals(exerciseId)))
        .get();
    await (_db.workoutSets.delete()
          ..where((s) =>
              s.workoutId.equals(session.workout.id) &
              s.exerciseId.equals(exerciseId)))
        .go();
    await _touchWorkout(session.workout.id, DateTime.now());
    final days = <DateTime>{
      for (final r in rows)
        if (r.isCompleted && r.loggedAt != null) dayOf(r.loggedAt!),
    };
    for (final d in days) {
      await _rollups.recomputeDay(d);
    }
    _addedExerciseOrder.remove(exerciseId);
    _pendingSupersetGroups.remove(exerciseId);
    ref.invalidateSelf();
    await future;
  }

  /// Link this exercise with the one after it into a superset group.
  Future<void> supersetWithNext(String exerciseId) async {
    _requireActive();
    final session = state.value!;
    final idx = session.exercises.indexWhere((e) => e.id == exerciseId);
    if (idx < 0 || idx + 1 >= session.exercises.length) return;
    final partner = session.exercises[idx + 1].id;

    var group = 1;
    for (final g in session.supersetGroups.values) {
      if (g >= group) group = g + 1;
    }
    _pendingSupersetGroups[exerciseId] = group;
    _pendingSupersetGroups[partner] = group;

    // Persist onto any existing sets of both exercises.
    final now = DateTime.now();
    await (_db.workoutSets.update()
          ..where((s) =>
              s.workoutId.equals(session.workout.id) &
              s.exerciseId.isIn([exerciseId, partner])))
        .write(WorkoutSetsCompanion(
      supersetGroup: Value(group),
      updatedAt: Value(now),
    ));
    await _touchWorkout(session.workout.id, now);
    ref.invalidateSelf();
    await future;
  }

  // ------------------------------- sets ----------------------------------

  Future<WorkoutSet> logSet({
    required String exerciseId,
    String setType = 'working',
    double? weightKg,
    int? reps,
    double? rpe,
    double? distanceM,
    int? durationSec,
    int? heartRate,
    String? notes,
  }) async {
    _requireActive();
    final session = state.value!;
    final now = DateTime.now();
    final id = _uuid.v4();
    // Order from the DB, not cached state — consecutive logSet calls may
    // race the lazy provider rebuild.
    final existing = await (_db.workoutSets.select()
          ..where((s) => s.workoutId.equals(session.workout.id)))
        .get();
    final maxOrder = existing.isEmpty
        ? 0
        : existing.map((s) => s.orderIndex).reduce((a, b) => a > b ? a : b) + 1;

    final set = WorkoutSetsCompanion.insert(
      id: id,
      workoutId: session.workout.id,
      exerciseId: exerciseId,
      orderIndex: maxOrder,
      setType: Value(setType),
      supersetGroup: Value(session.supersetGroups[exerciseId]),
      weightKg: Value(weightKg),
      reps: Value(reps),
      rpe: Value(rpe),
      distanceM: Value(distanceM),
      durationSec: Value(durationSec),
      heartRate: Value(heartRate),
      isCompleted: const Value(true),
      loggedAt: Value(now),
      notes: Value(notes),
      updatedAt: now,
    );
    await _db.workoutSets.insertOnConflictUpdate(set);
    await _touchWorkout(session.workout.id, now);
    await _rollups.recomputeDay(now);
    ref.invalidateSelf();
    return (_db.workoutSets.select()..where((s) => s.id.equals(id))).getSingle();
  }

  Future<void> updateSet(
    String setId, {
    String? setType,
    double? weightKg,
    int? reps,
    double? rpe,
    double? distanceM,
    int? durationSec,
    int? heartRate,
    String? notes,
    bool? complete,
  }) async {
    final current =
        await (_db.workoutSets.select()..where((s) => s.id.equals(setId)))
            .getSingleOrNull();
    final now = DateTime.now();
    await (_db.workoutSets.update()..where((s) => s.id.equals(setId))).write(
      WorkoutSetsCompanion(
        setType: setType != null ? Value(setType) : const Value.absent(),
        weightKg: weightKg != null ? Value(weightKg) : const Value.absent(),
        reps: reps != null ? Value(reps) : const Value.absent(),
        rpe: rpe != null ? Value(rpe) : const Value.absent(),
        distanceM:
            distanceM != null ? Value(distanceM) : const Value.absent(),
        durationSec:
            durationSec != null ? Value(durationSec) : const Value.absent(),
        heartRate: heartRate != null ? Value(heartRate) : const Value.absent(),
        notes: notes != null ? Value(notes) : const Value.absent(),
        // Completing a planned set stamps loggedAt the first time only.
        isCompleted: complete != null
            ? Value(complete)
            : const Value.absent(),
        loggedAt: complete == true && current?.loggedAt == null
            ? Value(now)
            : const Value.absent(),
        updatedAt: Value(now),
      ),
    );
    // The set may have just gained (or moved) its loggedAt day.
    final days = <DateTime>{dayOf(now)};
    if (current?.loggedAt != null) days.add(dayOf(current!.loggedAt!));
    if (current != null) await _touchWorkout(current.workoutId, now);
    for (final d in days) {
      await _rollups.recomputeDay(d);
    }
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteSet(String setId) async {
    final current =
        await (_db.workoutSets.select()..where((s) => s.id.equals(setId)))
            .getSingleOrNull();
    await (_db.workoutSets.delete()..where((s) => s.id.equals(setId))).go();
    if (current != null) {
      // The row is gone; bumping the parent is what tells sync to push the
      // workout again and replace its remote sets without this one.
      await _touchWorkout(current.workoutId, DateTime.now());
    }
    if (current?.isCompleted == true && current?.loggedAt != null) {
      await _rollups.recomputeDay(current!.loggedAt!);
    }
    ref.invalidateSelf();
    await future;
  }

  Future<void> saveWorkoutNotes(String notes) async {
    _requireActive();
    final session = state.value!;
    await (_db.workouts.update()
          ..where((w) => w.id.equals(session.workout.id)))
        .write(WorkoutsCompanion(
            notes: Value(notes), updatedAt: Value(DateTime.now())));
    ref.invalidateSelf();
    await future;
  }
}

// ---------------------------------------------------------------------------
// Rest timer — auto-started by the UI after a set is logged.
// ---------------------------------------------------------------------------

class RestTimerState {
  const RestTimerState({
    this.totalSeconds = 0,
    this.remainingSeconds = 0,
    this.running = false,
    this.finished = false,
  });

  final int totalSeconds;
  final int remainingSeconds;
  final bool running;
  final bool finished;

  double get progress =>
      totalSeconds == 0 ? 0 : (totalSeconds - remainingSeconds) / totalSeconds;

  String get label {
    final m = remainingSeconds ~/ 60;
    final s = (remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

final restTimerProvider =
    NotifierProvider<RestTimerNotifier, RestTimerState>(RestTimerNotifier.new);

class RestTimerNotifier extends Notifier<RestTimerState> {
  Timer? _timer;

  @override
  RestTimerState build() {
    ref.onDispose(() => _timer?.cancel());
    return const RestTimerState();
  }

  /// Starts (or restarts) the countdown; fires a notification at zero.
  void start(int seconds) {
    _timer?.cancel();
    state = RestTimerState(
      totalSeconds: seconds,
      remainingSeconds: seconds,
      running: true,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final remaining = state.remainingSeconds - 1;
    if (remaining <= 0) {
      _timer?.cancel();
      state = RestTimerState(
        totalSeconds: state.totalSeconds,
        remainingSeconds: 0,
        running: false,
        finished: true,
      );
      // Fire-and-forget; the service swallows its own errors.
      unawaited(ref.read(restNotificationProvider).showRestComplete());
    } else {
      state = RestTimerState(
        totalSeconds: state.totalSeconds,
        remainingSeconds: remaining,
        running: true,
      );
    }
  }

  void addSeconds(int seconds) {
    if (!state.running && !state.finished) return;
    state = RestTimerState(
      totalSeconds: state.totalSeconds + seconds,
      remainingSeconds: state.remainingSeconds + seconds,
      running: state.running,
      finished: false,
    );
  }

  void skip() => reset();

  void reset() {
    _timer?.cancel();
    state = const RestTimerState();
  }
}
