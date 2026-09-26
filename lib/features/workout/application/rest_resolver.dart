import 'package:drift/drift.dart';

import '../../../core/database/database.dart';
import '../../../core/settings/settings.dart';
import 'workout_session_notifier.dart';

/// Resolves the rest period after a set: **routine entry → exercise →
/// per-type Settings default**, in that order.
///
/// - Routine entry: the slot in the routine this session was started from,
///   only when it carries an explicit override ([inheritRestSeconds] means
///   "keep falling through"). Exercises added mid-session have no entry, so
///   they drop straight to the exercise/global levels.
/// - Exercise: [Exercises.restSeconds], null = no override.
/// - Global: [SettingsState.restWarmupSec] / [restWorkingSec] (drop shares
///   working) / [restFailureSec].
///
/// Returns seconds; `0` means "timer off" and the caller should skip
/// starting it.
Future<int> resolveRestSeconds({
  required AppDatabase db,
  required SettingsState settings,
  required WorkoutSession? session,
  required String exerciseId,
  required String setType,
}) async {
  // 1) routine override — only for the routine this workout came from.
  final routineId = session?.workout.routineId;
  if (routineId != null) {
    final entry = await (db.routineExercises.select()
          ..where((e) =>
              e.routineId.equals(routineId) &
              e.exerciseId.equals(exerciseId) &
              e.deletedAt.isNull())
          ..orderBy([(e) => OrderingTerm.asc(e.orderIndex)])
          ..limit(1))
        .getSingleOrNull();
    final rest = entry?.restSeconds;
    if (rest != null && rest != inheritRestSeconds) return rest.clamp(0, 86400);
  }

  // 2) exercise override.
  final exercise = await (db.exercises.select()
        ..where((e) => e.id.equals(exerciseId))
        ..limit(1))
      .getSingleOrNull();
  final exerciseRest = exercise?.restSeconds;
  if (exerciseRest != null) return exerciseRest.clamp(0, 86400);

  // 3) per-type Settings default.
  return switch (setType) {
    'warmup' => settings.restWarmupSec,
    'failure' => settings.restFailureSec,
    _ => settings.restWorkingSec, // working + drop (and unknown types)
  };
}
