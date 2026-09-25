import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Weekly "time to train" reminder, scheduled as a repeating local
/// notification (`matchDateTimeComponents: dayOfWeekAndTime` makes the
/// plugin re-arm the next occurrence after every fire and boot).
///
/// Exactness: alarms are exact (`exactAllowWhileIdle`) when the platform
/// already grants them — Android 12–13 grant SCHEDULE_EXACT_ALARM by
/// default once declared — and fall back to inexact on Android 14+ where
/// the permission is user-grantable. An inexact weekly reminder lands
/// within the system's alarm window (minutes), which is fine for a nudge
/// and avoids surprise permission screens.
///
/// Every call is guarded: widget tests have no platform channels, and a
/// missing reminder must never break the app.
class WeeklyReminderService {
  WeeklyReminderService({this.enabled = false});

  final bool enabled;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _zoneReady = false;

  static const _id = 0x2155; // rest timer uses 0x2154

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'weekly_reminder',
      'Workout reminders',
      channelDescription: 'Weekly nudge to train',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_stat_kinetic', // flat-white dumbbell in res/drawable
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
      _initialized = false; // never let this break settings
    }
  }

  /// Loads the IANA timezone database and points `tz.local` at the
  /// device's zone (platform channels → may be absent in tests).
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

  /// Next occurrence of [weekday] (1 = Mon … 7 = Sun) at hour:minute,
  /// strictly after [now] (equal counts as "not yet past"). Public and
  /// parameterised so the day-walk is testable without platform channels.
  static tz.TZDateTime nextOccurrence(
    tz.TZDateTime now,
    int weekday,
    int hour,
    int minute,
  ) {
    var next =
        tz.TZDateTime(now.location, now.year, now.month, now.day, hour, minute);
    while (next.isBefore(now) || next.weekday != weekday) {
      next = tz.TZDateTime(
          now.location, next.year, next.month, next.day + 1, hour, minute);
    }
    return next;
  }

  /// Next occurrence of [weekday] (1 = Mon … 7 = Sun) at hour:minute,
  /// strictly in the future.
  tz.TZDateTime _next(int weekday, int hour, int minute) =>
      nextOccurrence(tz.TZDateTime.now(tz.local), weekday, hour, minute);

  /// Arms (or re-arms) the weekly reminder. Calling again replaces the
  /// previous alarm — the id is stable.
  Future<void> schedule({
    required int weekday,
    required int hour,
    required int minute,
  }) async {
    if (!enabled) return;
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

      await _plugin.zonedSchedule(
        id: _id,
        title: 'Training time',
        body: 'Your workout is waiting — let’s get it done.',
        scheduledDate: _next(weekday, hour, minute),
        notificationDetails: _details,
        androidScheduleMode: mode,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (_) {}
  }

  Future<void> cancel() async {
    if (!enabled) return;
    try {
      await _plugin.cancel(id: _id);
    } catch (_) {}
  }
}

/// Disabled by default so tests and dev boots stay silent; main()
/// overrides it with an enabled instance.
final weeklyReminderProvider = Provider<WeeklyReminderService>(
  (ref) => WeeklyReminderService(enabled: false),
);
