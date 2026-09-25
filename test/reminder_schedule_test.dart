import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/core/notifications/weekly_reminder_service.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  tzdata.initializeTimeZones();

  // 2026-09-25 is a Friday (weekday 5); UTC keeps expectations exact.
  tz.TZDateTime fri(int hour) => tz.TZDateTime(tz.UTC, 2026, 9, 25, hour);

  group('WeeklyReminderService.nextOccurrence', () {
    test('same day when the weekday matches and the time is ahead', () {
      final next = WeeklyReminderService.nextOccurrence(fri(10), 5, 18, 0);
      expect(next, tz.TZDateTime(tz.UTC, 2026, 9, 25, 18));
    });

    test('a moment exactly at the target still fires today', () {
      final at = fri(18);
      expect(WeeklyReminderService.nextOccurrence(at, 5, 18, 0), at);
    });

    test('time already passed today → rolls to next week (month boundary)',
        () {
      final next = WeeklyReminderService.nextOccurrence(fri(19), 5, 18, 0);
      expect(next, tz.TZDateTime(tz.UTC, 2026, 10, 2, 18));
    });

    test('walks forward to a later weekday of the same week', () {
      // Friday → Sunday (2 days).
      final next = WeeklyReminderService.nextOccurrence(fri(10), 7, 18, 0);
      expect(next, tz.TZDateTime(tz.UTC, 2026, 9, 27, 18));
    });

    test('wraps around to the next Monday', () {
      final next = WeeklyReminderService.nextOccurrence(fri(10), 1, 18, 0);
      expect(next, tz.TZDateTime(tz.UTC, 2026, 9, 28, 18));
    });

    test('preserves minute precision', () {
      final next = WeeklyReminderService.nextOccurrence(fri(5), 5, 6, 30);
      expect(next, tz.TZDateTime(tz.UTC, 2026, 9, 25, 6, 30));
    });
  });
}
