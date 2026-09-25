/// Day-level progress math for one exercise — pure, no Flutter/Drift.
///
/// Input is a list of [ProgressPoint]s (one per training day, mapped from
/// the `ExerciseHistory` rollups). Everything the progress card shows —
/// records and the last-vs-previous session comparison — derives from
/// [ExerciseProgress.compute]. All dates are local-time calendar days.
library;

/// One training day for one exercise.
class ProgressPoint {
  const ProgressPoint({
    required this.date,
    required this.e1rmKg,
    required this.topWeightKg,
    required this.topReps,
    required this.volumeKg,
  });

  final DateTime date; // midnight of the training day
  final double e1rmKg;
  final double topWeightKg;
  final int topReps;
  final double volumeKg;
}

/// A record value and the day it happened.
class Best<T> {
  const Best(this.value, this.date);

  final T value;
  final DateTime date;
}

/// The last two sessions side by side (newest first is [last]).
class SessionComparison {
  const SessionComparison({required this.last, required this.previous});

  final ProgressPoint last;
  final ProgressPoint previous;

  double get e1rmDeltaKg => last.e1rmKg - previous.e1rmKg;
  double get volumeDeltaKg => last.volumeKg - previous.volumeKg;
}

/// Records + comparison for one exercise, computed from its day rows.
class ExerciseProgress {
  const ExerciseProgress({
    required this.newest,
    required this.bestE1rm,
    required this.bestSet,
    required this.bestVolumeDay,
    required this.comparison,
  });

  final ProgressPoint newest;

  /// All-time heaviest estimated 1RM.
  final Best<double> bestE1rm;

  /// All-time heaviest top set — tie broken by reps on the same weight.
  final Best<({double weightKg, int reps})> bestSet;

  /// Biggest single-day training volume.
  final Best<double> bestVolumeDay;

  /// Newest vs previous session — null until there are two sessions.
  final SessionComparison? comparison;

  /// null when the exercise has never been logged.
  static ExerciseProgress? compute(List<ProgressPoint> points) {
    if (points.isEmpty) return null;
    final sorted = [...points]..sort((a, b) => a.date.compareTo(b.date));

    var bestE1rm = Best(sorted.first.e1rmKg, sorted.first.date);
    var bestSet = Best(
      (weightKg: sorted.first.topWeightKg, reps: sorted.first.topReps),
      sorted.first.date,
    );
    var bestVolumeDay = Best(sorted.first.volumeKg, sorted.first.date);

    for (final p in sorted) {
      if (p.e1rmKg > bestE1rm.value) bestE1rm = Best(p.e1rmKg, p.date);
      final set = (weightKg: p.topWeightKg, reps: p.topReps);
      final current = bestSet.value;
      if (set.weightKg > current.weightKg ||
          (set.weightKg == current.weightKg && set.reps > current.reps)) {
        bestSet = Best(set, p.date);
      }
      if (p.volumeKg > bestVolumeDay.value) {
        bestVolumeDay = Best(p.volumeKg, p.date);
      }
    }

    return ExerciseProgress(
      newest: sorted.last,
      bestE1rm: bestE1rm,
      bestSet: bestSet,
      bestVolumeDay: bestVolumeDay,
      comparison: sorted.length >= 2
          ? SessionComparison(
              last: sorted.last,
              previous: sorted[sorted.length - 2],
            )
          : null,
    );
  }
}
