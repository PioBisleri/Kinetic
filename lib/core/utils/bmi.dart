/// Body mass index — display-only derived metric from the "Your data"
/// profile (height in cm, weight in kg) → kg/m². Null when either input
/// is missing or implausible.
double? bmiFor({double? heightCm, double? weightKg}) {
  if (heightCm == null || heightCm <= 0 || weightKg == null || weightKg <= 0) {
    return null;
  }
  final meters = heightCm / 100;
  return weightKg / (meters * meters);
}

enum BmiCategory { underweight, normal, overweight, obese }

/// WHO adult bands.
BmiCategory bmiCategory(double bmi) => switch (bmi) {
      < 18.5 => BmiCategory.underweight,
      < 25 => BmiCategory.normal,
      < 30 => BmiCategory.overweight,
      _ => BmiCategory.obese,
    };

String bmiLabel(BmiCategory category) => switch (category) {
      BmiCategory.underweight => 'Underweight',
      BmiCategory.normal => 'Normal',
      BmiCategory.overweight => 'Overweight',
      BmiCategory.obese => 'Obese',
    };
