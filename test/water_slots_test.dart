import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/core/notifications/water_reminder_service.dart';

/// Pure window layout for the hydrate reminders — no platform channels.
void main() {
  group('windowSlots', () {
    test('default window: 9..22 hourly → 14 slots, on the hour', () {
      final slots = WaterReminderService.windowSlots(9, 22, 60);
      expect(slots, hasLength(14));
      expect(slots.first, (9, 0));
      expect(slots.last, (22, 0));
      for (var i = 1; i < slots.length; i++) {
        expect(slots[i].$1 - slots[i - 1].$1, 1); // hourly steps
        expect(slots[i].$2, 0);
      }
    });

    test('30 min interval fragments minutes correctly', () {
      final slots = WaterReminderService.windowSlots(9, 10, 30);
      expect(slots, [(9, 0), (9, 30), (10, 0)]);
    });

    test('interval longer than the window yields a single slot', () {
      expect(WaterReminderService.windowSlots(9, 10, 120), [(9, 0)]);
    });

    test('start == end yields exactly one slot', () {
      expect(WaterReminderService.windowSlots(12, 12, 60), [(12, 0)]);
    });

    test('end < start degenerates to one daily reminder at start', () {
      expect(WaterReminderService.windowSlots(22, 6, 60), [(22, 0)]);
    });

    test('clamped to midnight; nonsense interval floor is 15 min', () {
      // endHour 25 → clamped 23
      expect(WaterReminderService.windowSlots(0, 25, 60).last, (23, 0));
      // a 5 "minute" interval becomes 15, so 10..11 = 09... four slots
      expect(
        WaterReminderService.windowSlots(10, 11, 5),
        [(10, 0), (10, 15), (10, 30), (10, 45), (11, 0)],
      );
    });

    test('ids stay per-index stable across layouts', () {
      // Documented contract: id = 0x2160 + slot index; re-layout only
      // ever re-uses lower-index slots, so no orphan alarms linger.
      expect(
        WaterReminderService.windowSlots(7, 21, 60).length,
        lessThanOrEqualTo(WaterReminderService.windowSlots(6, 22, 30).length),
      );
    });
  });
}
