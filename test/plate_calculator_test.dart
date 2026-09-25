import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/core/utils/plate_calculator.dart';

void main() {
  group('PlateCalculator', () {
    test('60 kg with a 20 kg bar → 20 per side, plate-optimal', () {
      final r = PlateCalculator.calculate(totalGrams: 60000, metric: true);
      expect(r.exact, isTrue);
      expect(r.plates, [20000]);
      expect(PlateCalculator.pretty(r.plates, metric: true), '1×20kg');
    });

    test('40 kg/side uses the minimal plate count (2, not greedy 3)', () {
      final r = PlateCalculator.calculate(
          totalGrams: 20000 + 2 * 40000, metric: true);
      expect(r.exact, isTrue);
      // Greedy would pick 25+10+5 (3 plates); DP finds any 2-plate
      // solution (20+20 or 25+15 — equally optimal in count).
      expect(r.plates.length, 2);
      expect(r.plates.reduce((a, b) => a + b), 40000);
    });

    test('odd load 62.5 kg → 20 + 10 + 2.5 + 1.25? resolves exactly', () {
      final r = PlateCalculator.calculate(totalGrams: 62500, metric: true);
      expect(r.exact, isTrue);
      // per side = 21.25 → 20 + 1.25
      expect(r.plates, [20000, 1250]);
    });

    test('target below bar weight is handled', () {
      final r = PlateCalculator.calculate(totalGrams: 15000, metric: true);
      expect(r.plates, isEmpty);
      expect(r.actualTotalGrams, 20000);
      expect(r.note, isNotNull);
    });

    test('imperial plates use lb denominations', () {
      // 135 lb barbell: (135-45)/2 = 45 lb → one 45 lb plate per side
      final r = PlateCalculator.calculate(
          totalGrams: (135 * 453.59237).round(),
          metric: false,
          barGrams: (45 * 453.59237).round());
      expect(r.exact, isTrue);
      expect(r.plates, [(45 * 453.59237).round()]);
      expect(PlateCalculator.pretty(r.plates, metric: false), '1×45lb');
    });

    test('microLoading=false drops 1.25s', () {
      final r = PlateCalculator.calculate(
          totalGrams: 20000 + 2 * 21250, // 62.5 total, needs 1.25s
          metric: true,
          microLoading: false);
      expect(r.exact, isFalse); // falls back to nearest reachable
    });
  });
}
