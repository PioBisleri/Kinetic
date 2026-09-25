/// Plate calculator — integer-gram DP for a plate-count-optimal load.
///
/// Greedy ("biggest plate first") would pick 25+10+5 for 40 kg/side when
/// 20+20 uses fewer plates; the DP always finds the minimal multiset.
class PlateCalculator {
  PlateCalculator._();

  /// Grams per plate, largest first.
  /// lb plates converted: 45 lb = 20412 g, 35 lb = 15876 g, ...
  static const kgPlates = [25000, 20000, 15000, 10000, 5000, 2500, 1250];
  static const lbPlates = [20412, 15876, 11340, 4536, 2268, 1134, 567];

  static const kgBar = 20000;
  static const kgWomensBar = 15000;
  static const kgTechniqueBar = 10000;

  /// Returns plates for ONE side of the bar, largest first.
  /// When [exact] is false the target wasn't reachable and [plates] is the
  /// closest achievable load (within 10%).
  static PlateResult calculate({
    required int totalGrams,
    required bool metric,
    int barGrams = kgBar,
    bool microLoading = true,
  }) {
    final allDenoms = metric ? kgPlates : lbPlates;
    final denominations =
        microLoading ? allDenoms : allDenoms.where((p) => p >= 2500).toList();

    if (totalGrams <= barGrams) {
      return PlateResult(
        plates: const [],
        exact: totalGrams == barGrams,
        actualTotalGrams: barGrams,
        note: totalGrams < barGrams ? 'Target is below bar weight' : null,
      );
    }

    final target = ((totalGrams - barGrams) / 2).round();

    const inf = 1 << 30;
    final dp = List.filled(target + 1, inf);
    final pick = List.filled(target + 1, -1);
    dp[0] = 0;

    for (var cap = 1; cap <= target; cap++) {
      for (final p in denominations) {
        if (p <= cap && dp[cap - p] + 1 < dp[cap]) {
          dp[cap] = dp[cap - p] + 1;
          pick[cap] = p;
        }
      }
    }

    var cap = target;
    if (dp[target] >= inf) {
      // Nearest reachable load at or below target (within 10%).
      var best = inf;
      for (var c = target; c >= (target * 0.9).round(); c--) {
        if (dp[c] < best) {
          best = dp[c];
          cap = c;
        }
      }
      if (best >= inf) {
        return PlateResult(
          plates: const [],
          exact: false,
          actualTotalGrams: barGrams,
          note: 'Unreachable with available plates',
        );
      }
    }

    final result = <int>[];
    var rest = cap;
    while (rest > 0) {
      result.add(pick[rest]);
      rest -= pick[rest];
    }
    result.sort((a, b) => b.compareTo(a));

    return PlateResult(
      plates: result,
      exact: cap == target,
      actualTotalGrams: barGrams + cap * 2,
    );
  }

  /// '2×25kg · 1×10kg · 1×2.5kg' — one side, grouped counts.
  static String pretty(List<int> plates, {required bool metric}) {
    if (plates.isEmpty) return 'bar only';
    final unit = metric ? 'kg' : 'lb';
    final counts = <int, int>{};
    for (final p in plates) {
      counts[p] = (counts[p] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return entries
        .map((e) => '${e.value}×${_fmt(e.key, metric)}$unit')
        .join(' · ');
  }

  static String _fmt(int grams, bool metric) {
    final v = metric ? grams / 1000 : grams / 453.59237;
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    // Up to 2 decimals, trailing zeros stripped (1.25kg, 2.5lb, 0.5lb…)
    return v.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }
}

class PlateResult {
  const PlateResult({
    required this.plates,
    required this.actualTotalGrams,
    this.exact = true,
    this.note,
  });

  final List<int> plates; // one side, largest first
  final bool exact;
  final int actualTotalGrams;
  final String? note;
}
