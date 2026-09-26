import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/core/settings/settings.dart';
import 'package:kinetic/core/utils/weight_units.dart';

void main() {
  group('formatElapsed', () {
    test('zero and sub-minute durations', () {
      expect(formatElapsed(Duration.zero), '0:00');
      expect(formatElapsed(const Duration(seconds: 9)), '0:09');
      expect(formatElapsed(const Duration(seconds: 59)), '0:59');
    });

    // Regression: the h == 0 branch used to render 'totalMinutes:minutes:
    // seconds' — 60s came out as 1:01:00 (an "added hour").
    test('minute marks render as m:ss, not h:mm:ss', () {
      expect(formatElapsed(const Duration(seconds: 60)), '1:00');
      expect(formatElapsed(const Duration(seconds: 61)), '1:01');
      expect(formatElapsed(const Duration(seconds: 120)), '2:00');
      expect(formatElapsed(const Duration(seconds: 125)), '2:05');
      expect(
          formatElapsed(const Duration(minutes: 45, seconds: 5)), '45:05');
    });

    test('durations of an hour or more render h:mm:ss', () {
      expect(formatElapsed(const Duration(hours: 1)), '1:00:00');
      expect(formatElapsed(const Duration(hours: 1, minutes: 1)), '1:01:00');
      expect(
          formatElapsed(const Duration(hours: 2, minutes: 2)), '2:02:00');
      expect(
          formatElapsed(
              const Duration(hours: 1, minutes: 14, seconds: 5)),
          '1:14:05');
    });
  });

  group('weight conversion', () {
    test('formatWeight trims trailing zeros in kg', () {
      expect(formatWeight(100, UnitSystem.kg), '100');
      expect(formatWeight(62.5, UnitSystem.kg), '62.5');
    });

    test('formatWeight snaps lbs to 0.5 increments', () {
      expect(formatWeight(100, UnitSystem.lbs), '220.5');
      expect(formatWeight(70, UnitSystem.lbs), '154.5');
    });

    test('displayToKg is the inverse of kgToDisplay', () {
      const kg = 82.5;
      final back = displayToKg(kgToDisplay(kg, UnitSystem.lbs), UnitSystem.lbs);
      expect(back, closeTo(kg, 1e-9));
    });
  });
}
