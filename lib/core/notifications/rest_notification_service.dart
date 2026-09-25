import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fires a system notification when a rest period ends.
///
/// v1 shows the notification via the plugin while the app is alive
/// (foreground or backgrounded). Exact delivery after the app process is
/// killed needs timezone-scheduled alarms — planned for Phase 7.
///
/// All calls are guarded: in widget tests the platform channel doesn't
/// exist, and a missing notification must never break a workout.
class RestNotificationService {
  RestNotificationService({this.enabled = false});

  final bool enabled;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'rest_timer',
      'Rest timer',
      channelDescription: 'Notifies when your rest period ends',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_stat_kinetic', // flat-white dumbbell in res/drawable
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> init() async {
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
      _initialized = false; // never let this block the app
    }
  }

  Future<void> showRestComplete() async {
    if (!enabled || !_initialized) return;
    try {
      await _plugin.show(
        id: 0x2154,
        title: 'Rest complete',
        body: 'Next set — let’s go.',
        notificationDetails: _details,
      );
    } catch (_) {}
  }

  Future<void> cancel() async {
    if (!enabled || !_initialized) return;
    try {
      await _plugin.cancel(id: 0x2154);
    } catch (_) {}
  }
}

/// Disabled by default so tests and unsigned/dev boots stay silent;
/// main() overrides it with an initialized, enabled instance.
final restNotificationProvider = Provider<RestNotificationService>(
  (ref) => RestNotificationService(enabled: false),
);
