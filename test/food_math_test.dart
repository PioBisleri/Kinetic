import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/utils/day_key.dart';
import 'package:kinetic/features/nutrition/domain/food_math.dart';

Food row({
  required double kcal,
  required double proteinG,
  required double carbsG,
  required double fatG,
}) =>
    Food(
      id: 'test-food',
      name: 'Chicken',
      servingSize: 100,
      servingUnit: 'g',
      kcal: kcal,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      isCustom: true,
      updatedAt: DateTime.now(),
    );

/// Pure nutrition math — no database, no Flutter.
void main() {
  group('scaleFood', () {
    test('scales every macro and keeps label kcal', () {
      final scaled = scaleFood(
        row(kcal: 165, proteinG: 31, carbsG: 0, fatG: 3.6),
        1.5,
      );
      expect(scaled.kcal, 247.5);
      expect(scaled.proteinG, 46.5);
      expect(scaled.carbsG, 0);
      expect(scaled.fatG, closeTo(5.4, 1e-9));
    });

    test('handles fractional servings', () {
      final scaled = scaleFood(
        row(kcal: 200, proteinG: 10, carbsG: 20, fatG: 5),
        0.5,
      );
      expect(scaled.kcal, 100);
      expect(scaled.proteinG, 5);
      expect(scaled.carbsG, 10);
      expect(scaled.fatG, 2.5);
    });
  });

  group('sum', () {
    test('adds the denormalized log rows directly, not re-scaled', () {
      final logs = [
        FoodLog(
          id: 'l1',
          dayKey: dayKey(DateTime.now()),
          name: 'Chicken',
          servings: 1,
          kcal: 165,
          proteinG: 31,
          carbsG: 0,
          fatG: 3.6,
          loggedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        FoodLog(
          id: 'l2',
          dayKey: dayKey(DateTime.now()),
          name: 'Rice',
          servings: 2,
          kcal: 400,
          proteinG: 8,
          carbsG: 80,
          fatG: 2,
          loggedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      final totals = sum(logs);
      expect(totals.kcal, 565);
      expect(totals.proteinG, 39);
      expect(totals.carbsG, 80);
      expect(totals.fatG, closeTo(5.6, 1e-9));
    });

    test('empty logs produce zero', () {
      final totals = sum(const []);
      expect(totals.kcal, 0);
      expect(totals.proteinG, 0);
      expect(totals.carbsG, 0);
      expect(totals.fatG, 0);
    });
  });

  group('kcalFromMacros', () {
    test('Atwater 4/4/9', () {
      expect(kcalFromMacros(25, 50, 10), 25 * 4 + 50 * 4 + 10 * 9);
    });
  });

  group('progress', () {
    test('clamps to 0..1 and guards zero targets', () {
      expect(progress(50, 100), 0.5);
      expect(progress(150, 100), 1);
      expect(progress(0, 100), 0);
      expect(progress(100, 0), 0); // no divide-by-zero
    });
  });
}
