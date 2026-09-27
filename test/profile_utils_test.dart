import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/core/utils/bmi.dart';
import 'package:kinetic/core/utils/height_units.dart';

void main() {
  group('bmiFor', () {
    test('180 cm at 72 kg → 22.2', () {
      final bmi = bmiFor(heightCm: 180, weightKg: 72);
      expect(bmi, isNotNull);
      expect(bmi!, closeTo(22.22, 0.01));
    });

    test('missing or implausible inputs → null', () {
      expect(bmiFor(heightCm: null, weightKg: 72), isNull);
      expect(bmiFor(heightCm: 180, weightKg: null), isNull);
      expect(bmiFor(heightCm: 0, weightKg: 72), isNull);
      expect(bmiFor(heightCm: 180, weightKg: -5), isNull);
    });
  });

  group('bmiCategory — WHO adult bands', () {
    test('boundaries', () {
      expect(bmiCategory(18.4), BmiCategory.underweight);
      expect(bmiCategory(18.5), BmiCategory.normal); // inclusive lower edge
      expect(bmiCategory(24.9), BmiCategory.normal);
      expect(bmiCategory(25), BmiCategory.overweight);
      expect(bmiCategory(29.9), BmiCategory.overweight);
      expect(bmiCategory(30), BmiCategory.obese);
      expect(bmiCategory(41.2), BmiCategory.obese);
    });

    test('labels', () {
      expect(bmiLabel(BmiCategory.underweight), 'Underweight');
      expect(bmiLabel(BmiCategory.normal), 'Normal');
      expect(bmiLabel(BmiCategory.overweight), 'Overweight');
      expect(bmiLabel(BmiCategory.obese), 'Obese');
    });
  });

  group('height units — cm is canonical, UI shows ft/in', () {
    test('cm → ft/in', () {
      expect(cmToFeetInches(180), (feet: 5, inches: 11));
      expect(cmToFeetInches(152.4), (feet: 5, inches: 0));
      expect(cmToFeetInches(170), (feet: 5, inches: 7));
      expect(cmToFeetInches(200), (feet: 6, inches: 7));
    });

    test('rounding spills a full 12 inches into the next foot', () {
      // 182.9 cm = 72.008 in → rounds to 6 ft 12 in before the spill.
      expect(cmToFeetInches(182.88), (feet: 6, inches: 0));
    });

    test('ft/in → cm round-trips within a rounding step', () {
      final cm = feetInchesToCm(5, 11);
      expect(cm, closeTo(180.34, 0.01));
      final back = cmToFeetInches(cm);
      expect(back, (feet: 5, inches: 11));
    });

    test('plausibility bounds 50–260 cm', () {
      expect(isValidHeightCm(49.9), isFalse);
      expect(isValidHeightCm(50), isTrue);
      expect(isValidHeightCm(180), isTrue);
      expect(isValidHeightCm(260), isTrue);
      expect(isValidHeightCm(260.1), isFalse);
      expect(isValidHeightCm(null), isFalse);
    });
  });
}
