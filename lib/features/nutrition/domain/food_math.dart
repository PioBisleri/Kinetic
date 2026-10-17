import '../../../core/database/database.dart';

/// Per-macro daily totals — values are already scaled by serving count,
/// since [FoodLog] rows snapshot the scaled macros at log time.
final class MacroTotals {
  const MacroTotals({
    this.kcal = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
  });

  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;

  static const zero = MacroTotals();
}

/// Pure nutrition math — no I/O, fully unit-testable.

/// A [Food]'s macros scaled by [servings] (may be fractional, e.g. 0.5
/// bowl). kcal comes from the food row, NOT from the macro formula — the
/// macros and the label kcal can disagree slightly, and the label wins
/// (consistency with what products print).
MacroTotals scaleFood(Food food, double servings) => MacroTotals(
      kcal: food.kcal * servings,
      proteinG: food.proteinG * servings,
      carbsG: food.carbsG * servings,
      fatG: food.fatG * servings,
    );

/// Sums any set of logs (one day's, or many).
MacroTotals sum(Iterable<FoodLog> logs) => MacroTotals(
      kcal: logs.fold(0, (a, l) => a + l.kcal),
      proteinG: logs.fold(0, (a, l) => a + l.proteinG),
      carbsG: logs.fold(0, (a, l) => a + l.carbsG),
      fatG: logs.fold(0, (a, l) => a + l.fatG),
    );

/// Atwater values — used only as display fallback when a manual entry
/// lacks kcal (`_logManual` sees to it the stored kcal matches this
/// formula, so totals are internally consistent).
double kcalFromMacros(double proteinG, double carbsG, double fatG) =>
    proteinG * 4 + carbsG * 4 + fatG * 9;

/// Progress fraction for the /diet bars, clamped to 0..1 — a 0 target
/// (feature not configured) never divides by zero and always reads "no
/// data" instead of infinity.
double progress(double done, double target) =>
    target <= 0 ? 0 : (done / target).clamp(0, 1);
