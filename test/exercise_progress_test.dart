import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/features/routines/domain/exercise_progress.dart';

void main() {
  final d1 = DateTime(2026, 9, 1);
  final d2 = DateTime(2026, 9, 8);
  final d3 = DateTime(2026, 9, 15);

  ProgressPoint point(
    DateTime date, {
    double e1rm = 0,
    double topWeight = 0,
    int topReps = 0,
    double volume = 0,
  }) =>
      ProgressPoint(
        date: date,
        e1rmKg: e1rm,
        topWeightKg: topWeight,
        topReps: topReps,
        volumeKg: volume,
      );

  group('compute', () {
    test('no sessions → null', () {
      expect(ExerciseProgress.compute(const []), isNull);
    });

    test('single session: records from it, no comparison', () {
      final p = ExerciseProgress.compute([
        point(d1, e1rm: 70, topWeight: 55, topReps: 5, volume: 2000),
      ])!;

      expect(p.newest.date, d1);
      expect(p.bestE1rm.value, 70);
      expect(p.bestE1rm.date, d1);
      expect(p.bestSet.value, (weightKg: 55.0, reps: 5));
      expect(p.bestVolumeDay.value, 2000);
      expect(p.comparison, isNull);
    });

    test('records pick the right day even when it is not the newest', () {
      final p = ExerciseProgress.compute([
        point(d1, e1rm: 70, topWeight: 55, topReps: 5, volume: 2000),
        point(d2, e1rm: 75, topWeight: 60, topReps: 5, volume: 2600),
        point(d3, e1rm: 73, topWeight: 62.5, topReps: 3, volume: 1800),
      ])!;

      // e1RM peaked on d2, weight on d3, volume on d2.
      expect(p.bestE1rm.value, 75);
      expect(p.bestE1rm.date, d2);
      expect(p.bestSet.value, (weightKg: 62.5, reps: 3));
      expect(p.bestSet.date, d3);
      expect(p.bestVolumeDay.value, 2600);
      expect(p.bestVolumeDay.date, d2);
      expect(p.newest.date, d3);
    });

    test('heaviest-set tie on weight is broken by reps', () {
      final p = ExerciseProgress.compute([
        point(d1, topWeight: 60, topReps: 3),
        point(d2, topWeight: 60, topReps: 8),
      ])!;

      expect(p.bestSet.value, (weightKg: 60.0, reps: 8));
      expect(p.bestSet.date, d2);
    });

    test('input order does not matter — sorted internally', () {
      final p = ExerciseProgress.compute([
        point(d3, e1rm: 73),
        point(d1, e1rm: 70),
        point(d2, e1rm: 75),
      ])!;

      expect(p.newest.date, d3);
      // Newest two = d2 (75) vs d3 (73).
      expect(p.comparison!.last.date, d3);
      expect(p.comparison!.previous.date, d2);
      expect(p.comparison!.e1rmDeltaKg, -2);
    });

    group('session comparison', () {
      test('signed e1RM and volume deltas', () {
        final p = ExerciseProgress.compute([
          point(d1, e1rm: 70, volume: 2000),
          point(d2, e1rm: 75, volume: 1600),
        ])!;

        expect(p.comparison, isNotNull);
        expect(p.comparison!.e1rmDeltaKg, 5);
        expect(p.comparison!.volumeDeltaKg, -400);
        expect(p.comparison!.last.date, d2);
        expect(p.comparison!.previous.date, d1);
      });

      test('identical sessions give zero deltas', () {
        final p = ExerciseProgress.compute([
          point(d1, e1rm: 70, volume: 2000),
          point(d2, e1rm: 70, volume: 2000),
        ])!;

        expect(p.comparison!.e1rmDeltaKg, 0);
        expect(p.comparison!.volumeDeltaKg, 0);
      });

      test('comparison only exists from the second session on', () {
        final p = ExerciseProgress.compute([
          point(d1, e1rm: 70, volume: 2000),
        ])!;
        expect(p.comparison, isNull);
      });
    });

    test('no points → null', () {
      expect(ExerciseProgress.compute(const []), isNull);
    });
  });
}
