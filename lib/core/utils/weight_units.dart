import '../settings/settings.dart';

/// kg is the canonical storage unit; everything here converts for display
/// and input only.
const _kgToLb = 2.2046226218;

double kgToDisplay(double kg, UnitSystem unit) =>
    unit == UnitSystem.kg ? kg : kg * _kgToLb;

double displayToKg(double value, UnitSystem unit) =>
    unit == UnitSystem.kg ? value : value / _kgToLb;

/// Pretty weight for the current unit: '100', '62.5', '137.5'.
String formatWeight(double kg, UnitSystem unit) {
  final v = kgToDisplay(kg, unit);
  if (unit == UnitSystem.lbs) {
    final rounded = (v * 2).round() / 2; // snap display to 0.5 lb
    return _trim(rounded);
  }
  return _trim(double.parse(v.toStringAsFixed(2)));
}

String _trim(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
}

/// Display-unit suffix: 'kg' or 'lb'.
String unitLabel(UnitSystem unit) => unit == UnitSystem.kg ? 'kg' : 'lb';

/// Big-stepper increment in display units → kg.
/// 2.5 kg / 5 lb matches the smallest common plate jump.
double stepKg(UnitSystem unit) =>
    displayToKg(unit == UnitSystem.kg ? 2.5 : 5, unit);

/// Elapsed formatting: 74:05 or 1:14:05.
String formatElapsed(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  // Under an hour the first field is TOTAL minutes; only pad h:mm:ss above.
  return h > 0 ? '$h:$m:$s' : '${d.inMinutes}:$s';
}
