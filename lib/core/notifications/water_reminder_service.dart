import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Daily "drink water" reminders, recurring every [interval] minutes
/// inside a start..end hour window (inclusive), modeled on
/// [WeeklyReminderService].
///
/// The plugin's `matchDateTimeComponents: time` re-arms a single alarm
/// daily at its hour:minute after every fire and boot — so one alarm per
/// slot makes the whole window recur every day without any scheduling
/// arithmetic beyond the initial layout. Ids are stable
/// (`_baseId + index`); scheduling always cancels the previous layout
/// first, so a narrowed window leaves no orphans.
///
/// Exactness/inexactness and the never-throw contract mirror the weekly
/// reminder: widget tests have no platform channels, and a missing
/// reminder must never break the app.
class WaterReminderService {
  WaterReminderService({this.enabled = false});

  final bool enabled;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _zoneReady = false;

  /// Slot alarms; the weekly reminder uses 0x2155, the rest timer 0x2154.
  static const _baseId = 0x2160;

  /// Layout of the reminder window in (hour, minute) alarm slots —
  /// [startHour] to [endHour] inclusive, stepped by [intervalMin],
  /// clamped to the valid daily range. A start past the end (which would
  /// wrap midnight) degenerates to a single daily reminder at the start
  /// hour.
  static List<(int, int)> windowSlots(
    int startHour,
    int endHour,
    int intervalMin,
  ) {
    final start = startHour.clamp(0, 23) * 60;
    final end = endHour.clamp(0, 23) * 60;
    final step = intervalMin.clamp(15, 240);
    if (end < start) return [(start ~/ 60, start % 60)];
    final slots = <(int, int)>[];
    for (var t = start; t <= end; t += step) {
      slots.add((t ~/ 60, t % 60));
    }
    return slots;
  }

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'water_reminder',
      'Water reminders',
      channelDescription: 'Recurring nudge to drink water',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_stat_kinetic',
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> _ensureInit() async {
    if (!enabled || _initialized) return;
    try {
      await _plugin.initialize(settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ));
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  Future<void> _ensureZone() async {
    if (_zoneReady) return;
    try {
      tzdata.initializeTimeZones();
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
      _zoneReady = true;
    } catch (_) {
      _zoneReady = false;
    }
  }

  /// Arms (or re-arms) the whole window. Any existing layout is cancelled
  /// first so re-scheduling never leaves slave alarms behind; the first
  /// slot fires at its next occurrence today/tomorrow.
  Future<void> schedule({
    required int startHour,
    required int endHour,
    required int intervalMin,
  }) async {
    if (!enabled) return;
    await cancel();
    await _ensureInit();
    if (!_initialized) return;
    await _ensureZone();
    if (!_zoneReady) return;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      var mode = AndroidScheduleMode.inexact;
      try {
        if (await android?.canScheduleExactNotifications() ?? false) {
          mode = AndroidScheduleMode.exactAllowWhileIdle;
        }
      } catch (_) {} // keep inexact

      final slots = windowSlots(startHour, endHour, intervalMin);
      for (var i = 0; i < slots.length; i++) {
        final (hour, minute) = slots[i];
        final now = tz.TZDateTime.now(tz.local);
        var next = tz.TZDateTime(now.location, now.year, now.month, now.day,
            hour, minute);
        if (!next.isAfter(now)) {
          next = next.add(const Duration(days: 1));
        }
        await _plugin.zonedSchedule(
          id: _baseId + i,
          title: 'Time to hydrate',
          body: 'Grab a glass of water.',
          scheduledDate: next,
          notificationDetails: _details,
          androidScheduleMode: mode,
          // Daily recurrence at the slot's own time.
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    } catch (_) {}
  }

  /// Cancel every possible slot, not just the last layout — a window only
  /// ever shrinks/grows while ids stay stable, and this also covers the
  /// "disabled" path without knowing the previous layout.
  Future<void> cancel() async {
    if (!enabled) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}

/// Disabled by default so tests and dev boots stay silent; main()
/// overrides it with an enabled instance.
final waterReminderProvider = Provider<WaterReminderService>(
  (ref) => WaterReminderService(enabled: false),
);
