import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/core/notifications/rest_notification_service.dart';
import 'package:kinetic/features/workout/application/workout_session_notifier.dart';

class _RecordingNotifications implements RestNotificationService {
  int restShown = 0;

  @override
  Future<void> init() async {}

  @override
  Future<void> showRestComplete() async => restShown++;

  @override
  Future<void> cancel() async {}

  @override
  final bool enabled = true;
}

void main() {
  late _RecordingNotifications notifications;
  late ProviderContainer container;

  setUp(() {
    notifications = _RecordingNotifications();
    container = ProviderContainer(overrides: [
      restNotificationProvider.overrideWithValue(notifications),
    ]);
    container.read(restTimerProvider); // run build() so state exists
  });

  tearDown(() => container.dispose());

  RestTimerNotifier notifier() =>
      container.read(restTimerProvider.notifier);
  RestTimerState state() => container.read(restTimerProvider);

  test('counts down and fires the notification exactly once at zero', () {
    fakeAsync((async) {
      notifier().start(10);
      expect(state().running, isTrue);
      expect(state().remainingSeconds, 10);

      async.elapse(const Duration(seconds: 4));
      expect(state().remainingSeconds, 6);
      expect(state().running, isTrue);
      expect(notifications.restShown, 0);

      async.elapse(const Duration(seconds: 6));
      expect(state().remainingSeconds, 0);
      expect(state().running, isFalse);
      expect(state().finished, isTrue);
      expect(notifications.restShown, 1);

      // No double-fire afterwards.
      async.elapse(const Duration(seconds: 5));
      expect(notifications.restShown, 1);
    });
  });

  test('+15s extends an active countdown', () {
    fakeAsync((async) {
      notifier().start(30);
      async.elapse(const Duration(seconds: 10));
      expect(state().remainingSeconds, 20);

      notifier().addSeconds(15);
      expect(state().remainingSeconds, 35);
      expect(state().totalSeconds, 45);

      async.elapse(const Duration(seconds: 1));
      expect(state().remainingSeconds, 34);
    });
  });

  test('skip resets to idle without firing', () {
    fakeAsync((async) {
      notifier().start(30);
      async.elapse(const Duration(seconds: 5));
      notifier().skip();
      expect(state().running, isFalse);
      expect(state().remainingSeconds, 0);

      async.elapse(const Duration(seconds: 40));
      expect(notifications.restShown, 0);
    });
  });

  test('restart replaces the previous countdown', () {
    fakeAsync((async) {
      notifier().start(60);
      async.elapse(const Duration(seconds: 20));
      notifier().start(10);
      expect(state().remainingSeconds, 10);

      async.elapse(const Duration(seconds: 10));
      expect(state().finished, isTrue);
      expect(notifications.restShown, 1);
    });
  });

  test('progress and label formatting', () {
    fakeAsync((async) {
      notifier().start(90);
      expect(state().progress, 0);
      expect(state().label, '1:30');

      async.elapse(const Duration(seconds: 30));
      expect(state().progress, closeTo(1 / 3, 0.001));
      expect(state().label, '1:00');
    });
  });
}
