import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/features/analytics/domain/analytics_math.dart';

void main() {
  group('date helpers', () {
    test('dayOf truncates to midnight', () {
      expect(dayOf(DateTime(2026, 9, 24, 15, 30)), DateTime(2026, 9, 24));
    });

    test('addDays normalizes month overflow', () {
      expect(addDays(DateTime(2026, 1, 30), 5), DateTime(2026, 2, 4));
      expect(addDays(DateTime(2026, 3, 1), -1), DateTime(2026, 2, 28));
    });

    test('weekStartOf lands on Monday for any weekday', () {
      // 2026-09-24 is a Thursday → Monday 2026-09-21.
      expect(weekStartOf(DateTime(2026, 9, 24, 18)), DateTime(2026, 9, 21));
      // Monday maps to itself; Sunday to the previous Monday.
      expect(weekStartOf(DateTime(2026, 9, 21)), DateTime(2026, 9, 21));
      expect(weekStartOf(DateTime(2026, 9, 27, 23, 59)), DateTime(2026, 9, 21));
    });

    test('daysBetween counts whole calendar days, both directions', () {
      expect(daysBetween(DateTime(2026, 9, 21), DateTime(2026, 9, 24)), 3);
      expect(daysBetween(DateTime(2026, 9, 24), DateTime(2026, 9, 21)), -3);
      expect(daysBetween(DateTime(2026, 9, 24, 23), DateTime(2026, 9, 25, 1)), 1);
    });

    test('periodStart covers exactly N Monday slots', () {
      // Now = Thursday 2026-09-24 → week starts 09-21;
      // a 4-week window starts Monday 2026-08-31.
      expect(periodStart(4, DateTime(2026, 9, 24, 18)), DateTime(2026, 8, 31));
      expect(periodStart(1, DateTime(2026, 9, 24, 18)), DateTime(2026, 9, 21));
    });

    test('periodStart(0) means All — the epoch', () {
      expect(periodStart(0, DateTime(2026, 9, 24, 18)), DateTime(1970));
    });

    test('chartStart keeps window starts but anchors All at first data',
        () {
      final now = DateTime(2026, 9, 24, 18);
      // Bounded periods ignore the dates entirely.
      expect(
        chartStart(4, now, [DateTime(2026, 9, 22)]),
        DateTime(2026, 8, 31),
      );
      // All → earliest data point, so the axis isn't 56 years wide.
      expect(
        chartStart(0, now, [DateTime(2026, 9, 22), DateTime(2026, 6, 1)]),
        DateTime(2026, 6, 1),
      );
      // All with no data falls back to the epoch.
      expect(chartStart(0, now, const []), DateTime(1970));
    });
  });

  group('bucketWeekly', () {
    // Now = Thursday 2026-09-24 → 4 slots: 08-31, 09-07, 09-14, 09-21.
    final now = DateTime(2026, 9, 24, 18);

    test('sums by week, keeps empty weeks, drops days outside', () {
      final points = bucketWeekly(
        [
          (date: DateTime(2026, 9, 22), volumeKg: 100.0), // week 09-21
          (date: DateTime(2026, 9, 23), volumeKg: 50.0), // same week
          (date: DateTime(2026, 9, 14), volumeKg: 400.0), // week 09-14
          (date: DateTime(2026, 8, 31), volumeKg: 75.0), // week 08-31
          (date: DateTime(2026, 8, 30), volumeKg: 999.0), // week 08-24: out
        ],
        now: now,
        weeks: 4,
      );

      expect(points, hasLength(4));
      expect(points[0].weekStart, DateTime(2026, 8, 31));
      expect(points[0].volumeKg, closeTo(75, 0.001));
      expect(points[1].weekStart, DateTime(2026, 9, 7));
      expect(points[1].volumeKg, 0); // empty week still present
      expect(points[2].volumeKg, closeTo(400, 0.001));
      expect(points[3].volumeKg, closeTo(150, 0.001));
    });

    test('an empty history produces all-zero buckets', () {
      final points = bucketWeekly(const [], now: now, weeks: 12);
      expect(points, hasLength(12));
      expect(points.every((p) => p.volumeKg == 0), isTrue);
    });

    test('weeks: 0 (All) sizes the window from the data', () {
      final points = bucketWeekly(
        [
          (date: DateTime(2026, 7, 6), volumeKg: 200.0), // 11 weeks back
          (date: DateTime(2026, 9, 22), volumeKg: 100.0), // this week
        ],
        now: now,
        weeks: 0,
      );
      // 07-06 is Monday 07-06 → 12 Monday slots through 09-21.
      expect(points, hasLength(12));
      expect(points.first.weekStart, DateTime(2026, 7, 6));
      expect(points.first.volumeKg, closeTo(200, 0.001));
      expect(points.last.volumeKg, closeTo(100, 0.001));
    });

    test('weeks: 0 with no data still yields one bucket', () {
      final points = bucketWeekly(const [], now: now, weeks: 0);
      expect(points, hasLength(1));
      expect(points.single.volumeKg, 0);
    });
  });

  group('weeklyStreak', () {
    // Now = Thursday 2026-09-24 (week of 09-21).
    final now = DateTime(2026, 9, 24, 18);

    test('no workouts → 0', () {
      expect(weeklyStreak(const [], now: now), 0);
    });

    test('trained this week → 1', () {
      expect(weeklyStreak([DateTime(2026, 9, 22)], now: now), 1);
    });

    test('multiple workouts in one week count once', () {
      expect(
        weeklyStreak([DateTime(2026, 9, 22), DateTime(2026, 9, 23)], now: now),
        1,
      );
    });

    test('consecutive weeks accumulate', () {
      expect(
        weeklyStreak(
          [DateTime(2026, 9, 22), DateTime(2026, 9, 15), DateTime(2026, 9, 8)],
          now: now,
        ),
        3,
      );
    });

    test('a missed week breaks the streak', () {
      // 09-14 week empty between 09-22 and 09-08.
      expect(
        weeklyStreak([DateTime(2026, 9, 22), DateTime(2026, 9, 8)], now: now),
        1,
      );
    });

    test('an unfinished current week gets grace', () {
      // Nothing yet this week; last weeks were trained.
      expect(
        weeklyStreak(
          [DateTime(2026, 9, 15), DateTime(2026, 9, 8), DateTime(2026, 9, 1)],
          now: now,
        ),
        3,
      );
      // Grace doesn't rescue a week missed two weeks back.
      expect(
        weeklyStreak([DateTime(2026, 9, 15), DateTime(2026, 9, 1)], now: now),
        1,
      );
    });
  });

  group('compactNumber', () {
    test('formats for axis labels', () {
      expect(compactNumber(0), '0');
      expect(compactNumber(625), '625');
      expect(compactNumber(999), '999');
      expect(compactNumber(12400), '12.4k');
      expect(compactNumber(105000), '105k');
    });
  });
}
