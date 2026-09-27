/// Double-progression suggestion engine — pure logic, no Flutter/Drift.
///
/// Given an exercise's completed hard sets from *prior* workouts (grouped
/// into sessions) and the current routine's rep target (if any), decide
/// what weight to suggest for the next set:
///
/// * **with a routine target** — classic double progression: hitting the
///   top of the rep range earns one increment; missing it means repeat the
///   weight; missing it at the *same* weight for [deloadAfterMisses]
///   sessions in a row means deload ~10% and build back up.
/// * **without a target** (free workout) — a set of ≥10 reps earns an
///   increment, anything else repeats the weight.
///
/// Weights are stored/returned in kg; `incrementKg` comes from the
/// exercise's progression override when set, else the unit setting
/// (2.5 kg / 5 lb via `stepKg`), so the engine stays unit-agnostic.
library;

/// One completed hard set from a prior workout.
class PriorSet {
  const PriorSet({
    required this.workoutId,
    required this.weightKg,
    required this.reps,
    required this.loggedAt,
  });

  final String workoutId;
  final double weightKg;
  final int reps;
  final DateTime loggedAt;
}

enum SuggestionAction { start, progress, repeat, deload }

class Suggestion {
  const Suggestion({
    required this.weightKg,
    required this.action,
    required this.reason,
    this.incrementKg = SuggestionEngine.defaultIncrementKg,
  });

  final double weightKg;
  final SuggestionAction action;
  final String reason; // short, user-facing

  /// The step this suggestion snapped to — echoed in the why-sheet so
  /// per-exercise overrides are visible.
  final double incrementKg;
}

class SuggestionEngine {
  const SuggestionEngine._();

  /// Default smallest load jump: one 1.25 kg plate per side.
  static const defaultIncrementKg = 2.5;

  /// Sessions that all missed [targetReps] at (about) the same weight.
  static const deloadAfterMisses = 3;

  /// Reps at or above which a free-workout set counts as "repped out".
  static const repOutThreshold = 10;

  /// [history] may be in any order; sets are grouped by [PriorSet.workoutId]
  /// and each session contributes its top set (highest weight, tie broken
  /// by reps). Returns null when there is nothing sensible to suggest.
  static Suggestion? suggest({
    required List<PriorSet> history,
    int? targetReps,
    double? targetWeightKg,
    double incrementKg = defaultIncrementKg,
  }) {
    final sessions = _sessions(history);

    if (sessions.isEmpty) {
      if (targetWeightKg != null && targetWeightKg > 0) {
        return Suggestion(
          weightKg: snap(targetWeightKg, incrementKg),
          action: SuggestionAction.start,
          reason: 'Routine target',
          incrementKg: incrementKg,
        );
      }
      return null;
    }

    final last = sessions.last;
    final hasTarget = targetReps != null && targetReps > 0;

    if (hasTarget) {
      if (last.reps >= targetReps) {
        return Suggestion(
          weightKg: snap(last.weightKg + incrementKg, incrementKg),
          action: SuggestionAction.progress,
          reason: 'Hit $targetReps reps last session',
          incrementKg: incrementKg,
        );
      }
      // Missed the target — deload if the last N sessions all stalled at
      // (about) this weight, otherwise grind toward the range at the same
      // weight.
      final recent = sessions.reversed.take(deloadAfterMisses).toList();
      final stalled = recent.length == deloadAfterMisses &&
          recent.every((s) =>
              s.reps < targetReps &&
              (last.weightKg - s.weightKg).abs() < incrementKg / 2);
      if (stalled) {
        final deloaded = snap(last.weightKg * 0.9, incrementKg);
        if (deloaded > 0 && deloaded < last.weightKg) {
          return Suggestion(
            weightKg: deloaded,
            action: SuggestionAction.deload,
            reason: '$deloadAfterMisses sessions stalled — reset ~10%',
            incrementKg: incrementKg,
          );
        }
      }
      return Suggestion(
        weightKg: snap(last.weightKg, incrementKg),
        action: SuggestionAction.repeat,
        reason: 'Working up to $targetReps reps',
        incrementKg: incrementKg,
      );
    }

    // Free workout — no prescription to progress against.
    if (last.reps >= repOutThreshold) {
      return Suggestion(
        weightKg: snap(last.weightKg + incrementKg, incrementKg),
        action: SuggestionAction.progress,
        reason: 'Repped out ${last.reps} reps',
        incrementKg: incrementKg,
      );
    }
    return Suggestion(
      weightKg: snap(last.weightKg, incrementKg),
      action: SuggestionAction.repeat,
      reason: last.reps <= 4
          ? 'Heavy set — repeat the weight'
          : 'Solid set — repeat to build volume',
      incrementKg: incrementKg,
    );
  }

  /// Per-workout top sets, oldest session first.
  static List<({double weightKg, int reps, DateTime at})> _sessions(
    List<PriorSet> history,
  ) {
    final byWorkout = <String, PriorSet>{};
    for (final s in history) {
      final cur = byWorkout[s.workoutId];
      if (cur == null ||
          s.weightKg > cur.weightKg ||
          (s.weightKg == cur.weightKg && s.reps > cur.reps)) {
        byWorkout[s.workoutId] = s;
      }
    }
    final out = byWorkout.values
        .map((s) => (weightKg: s.weightKg, reps: s.reps, at: s.loggedAt))
        .toList()
      ..sort((a, b) => a.at.compareTo(b.at));
    return out;
  }

  /// Nearest multiple of [increment] — kills float drift (57.499999 → 57.5).
  static double snap(double v, double increment) =>
      double.parse(((v / increment).round() * increment).toStringAsFixed(2));
}
