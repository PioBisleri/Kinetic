import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/features/workout/domain/suggestion_engine.dart';

void main() {
  final base = DateTime(2026, 1, 1, 10);

  PriorSet set(
    String workout, {
    double w = 60,
    int reps = 8,
    int day = 0,
  }) =>
      PriorSet(
        workoutId: workout,
        weightKg: w,
        reps: reps,
        loggedAt: base.add(Duration(days: day, hours: 1)),
      );

  group('history shaping', () {
    test('no history and no routine target → no suggestion', () {
      expect(
        SuggestionEngine.suggest(history: const []),
        isNull,
      );
    });

    test('no history but routine target → start at the target', () {
      final s = SuggestionEngine.suggest(
        history: const [],
        targetWeightKg: 40,
      );
      expect(s, isNotNull);
      expect(s!.action, SuggestionAction.start);
      expect(s.weightKg, 40);
    });

    test('top set of each session wins; sessions ordered by time', () {
      // w1 has a heavier set than w2's opener; the engine must use w2's
      // actual top set (70×6), not w1's, as the "last session".
      final s = SuggestionEngine.suggest(
        history: [
          set('w1', w: 65, reps: 5, day: -7),
          set('w1', w: 70, reps: 6, day: -7),
          set('w2', w: 67.5, reps: 4, day: 0),
          set('w2', w: 70, reps: 6, day: 0),
        ],
        targetReps: 8,
      );
      expect(s!.action, SuggestionAction.repeat);
      expect(s.weightKg, 70);
    });

    test('warm-up sets are the caller\'s filter — engine uses what it gets',
        () {
      // A single heavy top set is all the engine sees.
      final s = SuggestionEngine.suggest(
        history: [set('w1', w: 100, reps: 8, day: -3)],
        targetReps: 8,
      );
      expect(s!.action, SuggestionAction.progress);
      expect(s.weightKg, 102.5);
    });
  });

  group('double progression (routine target)', () {
    test('hitting the rep target earns one increment', () {
      final s = SuggestionEngine.suggest(
        history: [set('w1', w: 80, reps: 8, day: -3)],
        targetReps: 8,
      );
      expect(s!.action, SuggestionAction.progress);
      expect(s.weightKg, 82.5);
    });

    test('beating the target still earns exactly one increment', () {
      final s = SuggestionEngine.suggest(
        history: [set('w1', w: 80, reps: 11, day: -3)],
        targetReps: 8,
      );
      expect(s!.weightKg, 82.5);
    });

    test('missing the target repeats the weight', () {
      final s = SuggestionEngine.suggest(
        history: [set('w1', w: 80, reps: 6, day: -3)],
        targetReps: 8,
      );
      expect(s!.action, SuggestionAction.repeat);
      expect(s.weightKg, 80);
    });

    test('mixed misses at rising weights do not deload', () {
      // Two misses only — below the stall threshold — and the weights
      // moved between sessions, so no stall.
      final s = SuggestionEngine.suggest(
        history: [
          set('w1', w: 75, reps: 7, day: -10),
          set('w2', w: 80, reps: 6, day: -3),
        ],
        targetReps: 8,
      );
      expect(s!.action, SuggestionAction.repeat);
      expect(s.weightKg, 80);
    });

    test('three consecutive misses at the same weight → deload ~10%', () {
      final s = SuggestionEngine.suggest(
        history: [
          set('w1', w: 100, reps: 7, day: -21),
          set('w2', w: 100, reps: 6, day: -14),
          set('w3', w: 100, reps: 5, day: -7),
        ],
        targetReps: 8,
      );
      expect(s!.action, SuggestionAction.deload);
      expect(s.weightKg, 90); // 100 × 0.9, already on the 2.5 grid
    });

    test('stall that deloads off-grid snaps to the increment', () {
      final s = SuggestionEngine.suggest(
        history: [
          set('w1', w: 87.5, reps: 7, day: -21),
          set('w2', w: 87.5, reps: 7, day: -14),
          set('w3', w: 87.5, reps: 6, day: -7),
        ],
        targetReps: 8,
      );
      expect(s!.action, SuggestionAction.deload);
      // 87.5 × 0.9 = 78.75 → nearest 2.5 grid = 77.5? No: 78.75/2.5 = 31.5
      // → rounds to 32 → 80. Must still be strictly below 87.5.
      expect(s.weightKg, 80);
      expect(s.weightKg < 87.5, isTrue);
    });

    test('deload that would not reduce the weight falls back to repeat',
        () {
      final s = SuggestionEngine.suggest(
        history: [
          set('w1', w: 2.5, reps: 7, day: -21),
          set('w2', w: 2.5, reps: 7, day: -14),
          set('w3', w: 2.5, reps: 6, day: -7),
        ],
        targetReps: 8,
      );
      expect(s!.action, SuggestionAction.repeat);
      expect(s.weightKg, 2.5);
    });
  });

  group('free workout (no target)', () {
    test('10+ reps earns an increment', () {
      final s = SuggestionEngine.suggest(
        history: [set('w1', w: 60, reps: 10, day: -3)],
      );
      expect(s!.action, SuggestionAction.progress);
      expect(s.weightKg, 62.5);
    });

    test('mid-range reps repeat the weight', () {
      final s = SuggestionEngine.suggest(
        history: [set('w1', w: 60, reps: 7, day: -3)],
      );
      expect(s!.action, SuggestionAction.repeat);
      expect(s.weightKg, 60);
    });

    test('grinder (≤4 reps) repeats rather than deloads', () {
      final s = SuggestionEngine.suggest(
        history: [set('w1', w: 100, reps: 3, day: -3)],
      );
      expect(s!.action, SuggestionAction.repeat);
      expect(s.weightKg, 100);
    });

    test('routine target wins over free-workout heuristic', () {
      // 9 reps would be a free repeat, but the target is 8 → progress.
      final s = SuggestionEngine.suggest(
        history: [set('w1', w: 60, reps: 9, day: -3)],
        targetReps: 8,
      );
      expect(s!.action, SuggestionAction.progress);
    });
  });

  group('grids and increments', () {
    test('custom increment (lb mode: 5 lb ≈ 2.268 kg)', () {
      const inc = 2.268;
      final s = SuggestionEngine.suggest(
        history: [set('w1', w: 100, reps: 8, day: -3)],
        targetReps: 8,
        incrementKg: inc,
      );
      // 100 + 2.268 = 102.268 → snapped onto the 2.268 grid (45 × 2.268).
      expect(s!.weightKg, 102.06);
    });

    test('snap rounds float drift onto the grid', () {
      expect(SuggestionEngine.snap(57.4999999, 2.5), 57.5);
      expect(SuggestionEngine.snap(58.7, 2.5), 57.5); // nearest grid point
      expect(SuggestionEngine.snap(80.0001, 2.5), 80);
    });

    test('history order does not matter', () {
      final shuffled = [
        set('w3', w: 85, reps: 6, day: -7),
        set('w1', w: 82.5, reps: 8, day: -21),
        set('w2', w: 85, reps: 5, day: -14),
      ];
      final s = SuggestionEngine.suggest(
        history: shuffled,
        targetReps: 8,
      );
      expect(s!.weightKg, 85);
      expect(s.action, SuggestionAction.repeat);
    });
  });
}
