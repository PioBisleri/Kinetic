import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/settings/settings.dart';
import '../../../core/utils/weight_units.dart';
import '../../analytics/domain/analytics_math.dart';
import '../domain/suggestion_engine.dart';

/// Next-set suggestion for one exercise (null = nothing sensible yet).
///
/// Stream-based and auto-disposing: a cached non-autoDispose family would
/// keep whatever it last emitted (possibly evaluated while some *other*
/// workout was active) and pause its upstream between sheets. Here every
/// sheet open re-evaluates against the current active workout — routine
/// targets and the self-exclusion change with it — while the streams keep
/// the value live for the sheet's lifetime.
///
/// Prior sessions only: the active workout's own sets are excluded so
/// nothing feeds back into itself — in-session repetition is handled by
/// the editor's "prefill last set".
final exerciseSuggestionProvider =
    StreamProvider.autoDispose.family<Suggestion?, String>(
  (ref, exerciseId) {
    final db = ref.watch(databaseProvider);
    final unit = ref.watch(settingsProvider).unit;

    return db.watchActiveWorkout().asyncExpand((active) async* {
      // Routine prescription, if this workout came from one.
      int? targetReps;
      double? targetWeightKg;
      final routineId = active?.routineId;
      if (routineId != null) {
        final planned = await (db.routineExercises.select()
              ..where((e) =>
                  e.routineId.equals(routineId) &
                  e.exerciseId.equals(exerciseId) &
                  e.deletedAt.isNull())
              ..limit(1))
            .getSingleOrNull();
        targetReps = planned?.targetReps;
        targetWeightKg = planned?.targetWeight;
      }

      // Per-exercise progression override; null = unit default.
      final exercise = await (db.exercises.select()
            ..where((e) => e.id.equals(exerciseId))
            ..limit(1))
          .getSingleOrNull();
      final incrementKg = exercise?.progressionIncrementKg ?? stepKg(unit);

      // Prior completed hard sets for this exercise.
      final query = db.workoutSets.select()
        ..where((s) =>
            s.exerciseId.equals(exerciseId) &
            s.isCompleted.equals(true) &
            s.setType.isIn(hardSetTypes.toList()) &
            s.weightKg.isNotNull() &
            s.reps.isNotNull() &
            s.loggedAt.isNotNull())
        ..orderBy([(s) => OrderingTerm.asc(s.loggedAt)]);
      if (active != null) {
        query.where((s) => s.workoutId.isNotValue(active.id));
      }

      yield* query.watch().map(
            (rows) => SuggestionEngine.suggest(
              history: [
                for (final s in rows)
                  PriorSet(
                    workoutId: s.workoutId,
                    weightKg: s.weightKg!,
                    reps: s.reps!,
                    loggedAt: s.loggedAt!,
                  ),
              ],
              targetReps: targetReps,
              targetWeightKg: targetWeightKg,
              incrementKg: incrementKg,
            ),
          );
    });
  },
);
