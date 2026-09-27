/// Height conversions — cm is the canonical storage unit (like kg for
/// weight); the imperial UI shows feet + inches, never total inches.
const _cmPerInch = 2.54;
const _inchesPerFoot = 12;

/// 180 cm → (5, 11). Rounding can spill 12 in into the next foot.
({int feet, int inches}) cmToFeetInches(double cm) {
  final totalInches = cm / _cmPerInch;
  var feet = totalInches ~/ _inchesPerFoot;
  var inches = (totalInches - feet * _inchesPerFoot).round();
  if (inches >= _inchesPerFoot) {
    feet += 1;
    inches -= _inchesPerFoot;
  }
  return (feet: feet, inches: inches);
}

double feetInchesToCm(int feet, int inches) =>
    (feet * _inchesPerFoot + inches) * _cmPerInch;

/// Plausibility bounds for user input (50–260 cm).
bool isValidHeightCm(double? cm) => cm != null && cm >= 50 && cm <= 260;
