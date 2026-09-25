import 'dart:math' as math;

/// Muscle Grade engine — pure functions, no Flutter/Drift dependencies,
/// so it's trivially unit-testable.
///
/// score = 0.40·volume + 0.40·strength + 0.20·consistency   (each 0..100)
///
/// Inputs are gathered over a rolling 30-day window per muscle group.
class GradeEngine {
  GradeEngine._();

  // ---- configuration (candidate for a user-tunable settings table) --------

  /// Target weekly hard-set volume per muscle group (kg).
  static const volumeWeekTarget = 8000.0;
  static const volumeRef = 1000.0; // compression constant

  /// Sessions expected per 30 days (≈2×/week).
  static const defaultTargetSessions = 8;

  /// Freshness: credit decays to 0 after 72h without training.
  static const freshnessHalfWindowH = 72.0;

  /// Standardised target e1RM as a multiple of bodyweight for the muscle's
  /// main lift. Used to normalise strength across muscles.
  static const e1RmTargetsPerBw = <String, double>{
    'chest': 1.0, // bench
    'upper_chest': 0.85,
    'lats': 1.1, // pulldown/row standards are looser
    'traps': 1.2, // deadlift-ish
    'rhomboids': 1.0,
    'spinal_erectors': 2.0, // deadlift
    'front_delts': 0.6, // OHP
    'side_delts': 0.25,
    'rear_delts': 0.3,
    'biceps': 0.4,
    'triceps': 0.6,
    'forearms': 0.35,
    'abs': 0.0, // no direct 1RM standard — strength component skipped
    'obliques': 0.0,
    'quads': 1.5, // squat
    'hamstrings': 1.4,
    'glutes': 1.8, // hip thrust / deadlift
    'calves': 0.8,
  };

  static const weights = (volume: 0.40, strength: 0.40, consistency: 0.20);

  /// Epley estimate. Only meaningful for reps ≤ 10 (callers filter).
  static double epley1Rm(double weightKg, int reps) =>
      weightKg * (1 + reps / 30);

  // ---- components ---------------------------------------------------------

  /// Log-normalised volume score for [volumeKg] accumulated over the window.
  static double volumeScore(double volumeKg, {double weeksInWindow = 4.33}) {
    final target = volumeWeekTarget * weeksInWindow;
    if (volumeKg <= 0) return 0;
    final score =
        100 * _ln(1 + volumeKg / volumeRef) / _ln(1 + target / volumeRef);
    return score.clamp(0.0, 100.0);
  }

  /// Strength score from the muscle's best e1RM relative to a bodyweight
  /// standard (0.8 exponent softens the top end for beginners).
  static double strengthScore({
    required double? bestE1RmKg,
    required double bodyweightKg,
    required String muscleId,
  }) {
    final target = e1RmTargetsPerBw[muscleId];
    if (bestE1RmKg == null ||
        bestE1RmKg <= 0 ||
        bodyweightKg <= 0 ||
        target == null ||
        target <= 0) {
      return 0;
    }
    final ratio = bestE1RmKg / (bodyweightKg * target);
    return (100 * _pow(ratio, 0.8)).clamp(0.0, 100.0);
  }

  /// Frequency vs target, damped by how recently the muscle was trained.
  static double consistencyScore({
    required int daysTrained,
    required int targetSessions,
    required double hoursSinceTrained,
  }) {
    final frequency =
        (daysTrained / (targetSessions <= 0 ? defaultTargetSessions : targetSessions))
            .clamp(0.0, 1.0);
    final freshness = (1 - hoursSinceTrained / freshnessHalfWindowH)
        .clamp(0.0, 1.0);
    return (100 * frequency * (0.6 + 0.4 * freshness)).clamp(0.0, 100.0);
  }

  // ---- composite ----------------------------------------------------------

  static GradeResult grade({
    required String muscleId,
    required double volumeKg30d,
    required double? bestE1RmKg,
    required double bodyweightKg,
    required int daysTrained30d,
    required int targetSessions,
    required double hoursSinceTrained,
  }) {
    final v = volumeScore(volumeKg30d);
    final s = strengthScore(
      bestE1RmKg: bestE1RmKg,
      bodyweightKg: bodyweightKg,
      muscleId: muscleId,
    );
    final c = consistencyScore(
      daysTrained: daysTrained30d,
      targetSessions: targetSessions,
      hoursSinceTrained: hoursSinceTrained,
    );

    final score = weights.volume * v + weights.strength * s + weights.consistency * c;
    return GradeResult(
      muscleId: muscleId,
      score: score.clamp(0.0, 100.0),
      grade: tier(score),
      volumeScore: v,
      strengthScore: s,
      consistencyScore: c,
    );
  }

  /// S ≥ 90 · A ≥ 78 · B ≥ 64 · C ≥ 48 · D ≥ 30 · F < 30
  static String tier(double score) {
    if (score >= 90) return 'S';
    if (score >= 78) return 'A';
    if (score >= 64) return 'B';
    if (score >= 48) return 'C';
    if (score >= 30) return 'D';
    return 'F';
  }

  // ---- balance ------------------------------------------------------------

  static BalanceStatus balance({
    required double scoreA,
    required double scoreB,
    required double targetMin,
    required double targetMax,
  }) {
    if (scoreB <= 0 && scoreA <= 0) return BalanceStatus('—', true, null);
    final ratio = scoreB <= 0 ? 999.0 : scoreA / scoreB;
    final ok = ratio >= targetMin && ratio <= targetMax;
    String label;
    if (ok) {
      label = 'Balanced';
    } else if (ratio < targetMin) {
      // A/B below the band → the A side lags the B side.
      label = 'A side undertrained';
    } else {
      // A/B above the band → the B side lags the A side.
      label = 'B side undertrained';
    }
    return BalanceStatus(label, ok, ratio);
  }

  // ---- heat map freshness (shared with the body map renderer) ------------

  /// 0 (untrained/cold) .. 1 (trained today).
  static double freshness({required double hoursSinceTrained}) =>
      (1 - hoursSinceTrained / freshnessHalfWindowH).clamp(0.0, 1.0);

  // ---- tiny math helpers (avoid dart:math import churn in tests) ----------

  static double _ln(double x) => math.log(x);

  static double _pow(double b, double e) => math.pow(b, e).toDouble();
}

class GradeResult {
  const GradeResult({
    required this.muscleId,
    required this.score,
    required this.grade,
    required this.volumeScore,
    required this.strengthScore,
    required this.consistencyScore,
  });

  final String muscleId;
  final double score;
  final String grade;
  final double volumeScore;
  final double strengthScore;
  final double consistencyScore;
}

class BalanceStatus {
  const BalanceStatus(this.label, this.isBalanced, this.ratio);
  final String label;
  final bool isBalanced;
  final double? ratio;
}


