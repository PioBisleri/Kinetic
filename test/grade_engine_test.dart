import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/features/analytics/domain/grade_engine.dart';

void main() {
  group('GradeEngine.tier', () {
    test('maps scores to F/D/C/B/A/S bands', () {
      expect(GradeEngine.tier(95), 'S');
      expect(GradeEngine.tier(90), 'S');
      expect(GradeEngine.tier(89.9), 'A');
      expect(GradeEngine.tier(78), 'A');
      expect(GradeEngine.tier(64), 'B');
      expect(GradeEngine.tier(48), 'C');
      expect(GradeEngine.tier(30), 'D');
      expect(GradeEngine.tier(29.9), 'F');
    });
  });

  group('GradeEngine.volumeScore', () {
    test('zero volume → zero', () {
      expect(GradeEngine.volumeScore(0), 0);
    });

    test('hitting the 4-week target → 100 (log ratio = 1 by construction)',
        () {
      // target = 8000 kg/week * 4.33 weeks
      expect(GradeEngine.volumeScore(8000.0 * 4.33), closeTo(100, 0.001));
      // half the target still grades respectably (diminishing returns)
      final half = GradeEngine.volumeScore(8000.0 * 4.33 / 2);
      expect(half, greaterThan(75));
      expect(half, lessThan(90));
    });

    test('is monotonically increasing (and clamps at 100)', () {
      double prev = -1;
      for (final v in <double>[1000.0, 5000, 20000, 34000]) {
        final s = GradeEngine.volumeScore(v);
        expect(s, greaterThan(prev));
        prev = s;
      }
      expect(GradeEngine.volumeScore(500000), 100); // clamped
    });
  });

  group('GradeEngine.strengthScore', () {
    test('at bodyweight standard (ratio 1.0) → 100', () {
      final s = GradeEngine.strengthScore(
        bestE1RmKg: 100,
        bodyweightKg: 100,
        muscleId: 'chest', // target 1.0×BW
      );
      expect(s, closeTo(100, 0.001));
    });

    test('half the standard → clearly penalised but nonzero', () {
      final s = GradeEngine.strengthScore(
        bestE1RmKg: 50,
        bodyweightKg: 100,
        muscleId: 'chest',
      );
      expect(s, greaterThan(40));
      expect(s, lessThan(75));
    });

    test('muscle without a standard (abs) → 0', () {
      expect(
        GradeEngine.strengthScore(
          bestE1RmKg: 50,
          bodyweightKg: 80,
          muscleId: 'abs',
        ),
        0,
      );
    });
  });

  group('GradeEngine.consistencyScore', () {
    test('full frequency + trained today → 100', () {
      expect(
        GradeEngine.consistencyScore(
          daysTrained: 8,
          targetSessions: 8,
          hoursSinceTrained: 0,
        ),
        closeTo(100, 0.001),
      );
    });

    test('fades to ~60 at 72h (even at full frequency)', () {
      final s = GradeEngine.consistencyScore(
        daysTrained: 8,
        targetSessions: 8,
        hoursSinceTrained: 72,
      );
      expect(s, closeTo(60, 0.001));
    });

    test('never exceeds 100 even with extra sessions', () {
      expect(
        GradeEngine.consistencyScore(
          daysTrained: 30,
          targetSessions: 8,
          hoursSinceTrained: 0,
        ),
        lessThanOrEqualTo(100),
      );
    });
  });

  group('GradeEngine.grade (composite)', () {
    test('well-rounded lifter grades high', () {
      final g = GradeEngine.grade(
        muscleId: 'quads',
        volumeKg30d: 40000,
        bestE1RmKg: 170,
        bodyweightKg: 100,
        daysTrained30d: 10,
        targetSessions: 8,
        hoursSinceTrained: 12,
      );
      expect(g.score, greaterThan(60));
      expect('SFABCD'.contains(g.grade), isTrue);
    });

    test('detrained neglected muscle loses grade', () {
      final fresh = GradeEngine.grade(
        muscleId: 'calves',
        volumeKg30d: 8000,
        bestE1RmKg: null,
        bodyweightKg: 100,
        daysTrained30d: 6,
        targetSessions: 8,
        hoursSinceTrained: 6,
      );
      final stale = GradeEngine.grade(
        muscleId: 'calves',
        volumeKg30d: 8000,
        bestE1RmKg: null,
        bodyweightKg: 100,
        daysTrained30d: 6,
        targetSessions: 8,
        hoursSinceTrained: 70,
      );
      expect(stale.score, lessThan(fresh.score));
    });

    test('score stays within 0..100', () {
      final g = GradeEngine.grade(
        muscleId: 'chest',
        volumeKg30d: 500000,
        bestE1RmKg: 400,
        bodyweightKg: 60,
        daysTrained30d: 30,
        targetSessions: 8,
        hoursSinceTrained: 0,
      );
      expect(g.score, inInclusiveRange(0, 100));
    });
  });

  group('GradeEngine.freshness', () {
    test('heat map curve 1 → 0 over 72 hours', () {
      expect(GradeEngine.freshness(hoursSinceTrained: 0), 1);
      expect(GradeEngine.freshness(hoursSinceTrained: 36), closeTo(0.5, 0.01));
      expect(GradeEngine.freshness(hoursSinceTrained: 72), 0);
      expect(GradeEngine.freshness(hoursSinceTrained: 200), 0);
    });
  });

  group('GradeEngine.balance', () {
    test('ratio inside the band → Balanced', () {
      final s = GradeEngine.balance(
        scoreA: 1000,
        scoreB: 1000,
        targetMin: 0.85,
        targetMax: 1.15,
      );
      expect(s.isBalanced, isTrue);
      expect(s.label, 'Balanced');
      expect(s.ratio, closeTo(1.0, 0.001));
    });

    test('A/B below the band → A side undertrained', () {
      final s = GradeEngine.balance(
        scoreA: 500,
        scoreB: 1000,
        targetMin: 0.85,
        targetMax: 1.15,
      );
      expect(s.isBalanced, isFalse);
      expect(s.label, 'A side undertrained');
      expect(s.ratio, closeTo(0.5, 0.001));
    });

    test('A/B above the band → B side undertrained', () {
      final s = GradeEngine.balance(
        scoreA: 2000,
        scoreB: 1000,
        targetMin: 0.85,
        targetMax: 1.15,
      );
      expect(s.isBalanced, isFalse);
      expect(s.label, 'B side undertrained');
    });

    test('missing B side → B side undertrained', () {
      final s = GradeEngine.balance(
        scoreA: 2000,
        scoreB: 0,
        targetMin: 0.85,
        targetMax: 1.15,
      );
      expect(s.ratio, greaterThan(900));
      expect(s.label, 'B side undertrained');
    });

    test('no data on either side → em dash', () {
      final s = GradeEngine.balance(
        scoreA: 0,
        scoreB: 0,
        targetMin: 0.85,
        targetMax: 1.15,
      );
      expect(s.ratio, isNull);
      expect(s.label, '—');
      expect(s.isBalanced, isTrue);
    });
  });
}
