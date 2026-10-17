import 'dart:async' show StreamSubscription;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/database.dart';
import '../../core/utils/day_key.dart';

/// Pure step-count bookkeeping — no platform calls, fully unit-testable.
///
/// The Android step-counter sensor reports a SCHEME-CUMULATIVE count since
/// the last reboot; per-day totals are derived here:
///
/// * baseline       — cumulative reading at the moment the current day's
///                    baseline was set (stored in prefs);
/// * day-key        — the local day the baseline belongs to;
/// * today's steps  — cumulative − baseline while the day is unchanged.
///
/// Two discontinuities, handled in this fixed order:
/// 1. **Day rollover** (step 1): the day-key changed → rebase to the
///    current cumulative and zero the count. Steps walked while the app
///    was dead across midnight (cumulative kept running) are lost — that
///    is a sensor limitation, and inventing numbers is against the
///    project's no-fabrication stance.
/// 2. **Device reboot** (step 2): cumulative < baseline → rebase to the
///    current cumulative and zero the count; the sensor restarted at 0.
final class StepMath {
  static const prefsDayKey = 'steps_day_key';
  static const prefsBaseline = 'steps_baseline';

  /// Returns the new persisted state and the day's step count after
  /// absorbing one sensor reading. The returned count is only meaningful
  /// for [todayKey]-keyed rows.
  static ({String dayKey, int baseline, int today}) absorb({
    required int cumulative,
    required String todayKey,
    required String storedDayKey,
    required int storedBaseline,
  }) {
    // 1. Day rollover wins: count what the new day has accumulated so far.
    if (todayKey != storedDayKey) {
      return (dayKey: todayKey, baseline: cumulative, today: 0);
    }
    // 2. Sensor restarted (reboot): its cumulative dropped below zero.
    if (cumulative < storedBaseline) {
      return (dayKey: storedDayKey, baseline: cumulative, today: 0);
    }
    // 3. Normal flow.
    return (dayKey: storedDayKey, baseline: storedBaseline, today: cumulative - storedBaseline);
  }
}

/// Listens to the step-counter sensor and keeps `body_metrics.steps` for
/// the current day up to date.
///
/// Contract mirrored from the notification services: every platform call
/// is guarded — the channel is absent in widget tests, the permission can
/// be denied, and none of that may break the app. Writes are throttled:
/// [Pedometer] emits per step, and a local-SQLite write per step is both
/// pointless and awake-wallet hostile; 15 s batched.
class StepTrackerService {
  StepTrackerService({
    required this.prefs,
    required this.onDaySteps,
  });

  final SharedPreferences prefs;

  /// Persists the day's step count (today's row). Called at most once per
  /// throttle window with the steps so far.
  final Future<void> Function(String dayKey, int steps) onDaySteps;

  StreamSubscription<StepCount>? _sub;
  String _dayKey = '';
  int _baseline = 0;
  int _lastPersisted = -1;
  DateTime _lastWrite = DateTime.fromMillisecondsSinceEpoch(0);

  bool get isRunning => _sub != null;

  /// Requests the activity-recognition permission and starts listening.
  /// Returns false (and stays off) when the permission is denied or the
  /// platform has no channel — never throws.
  Future<bool> start() async {
    if (_sub != null) return true;
    try {
      var granted = await Permission.activityRecognition.isGranted;
      if (!granted) {
        final result = await Permission.activityRecognition.request();
        granted = result.isGranted;
      }
      if (!granted) return false;
    } catch (_) {
      return false; // channel absent (tests) or permission layer missing
    }
    return _listen();
  }

  Future<bool> _listen() async {
    _dayKey = prefs.getString(StepMath.prefsDayKey) ?? '';
    _baseline = prefs.getInt(StepMath.prefsBaseline) ?? 0;
    try {
      _sub = Pedometer.stepCountStream.listen(_onStepCount, onError: (_) {});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  /// One absorb → at most one persist, with writes skipped entirely when
  /// the count hasn't moved by a worthwhile amount inside the window.
  Future<void> _onStepCount(StepCount event) async {
    try {
      final result = StepMath.absorb(
        cumulative: event.steps,
        todayKey: dayKey(DateTime.now()),
        storedDayKey: _dayKey,
        storedBaseline: _baseline,
      );
      _dayKey = result.dayKey;
      _baseline = result.baseline;
      await prefs.setString(StepMath.prefsDayKey, result.dayKey);
      await prefs.setInt(StepMath.prefsBaseline, result.baseline);

      final now = DateTime.now();
      final movedEnough = (result.today - _lastPersisted).abs() >= 15;
      final windowElapsed =
          now.difference(_lastWrite) >= const Duration(seconds: 15);
      if (_lastPersisted >= 0 && !movedEnough && !windowElapsed) return;
      _lastPersisted = result.today;
      _lastWrite = now;
      await onDaySteps(result.dayKey, result.today);
    } catch (_) {}
  }
}

/// Overrides in main() with a real instance; widget tests never touch it.
final stepTrackerProvider = Provider<StepTrackerService>(
  (ref) => throw UnimplementedError('overridden in main()'),
);

/// Body-metrics write that merges the steps column into today's row —
/// must never clobber a weigh-in or water logged the same day.
Future<void> setDaySteps(AppDatabase db, String dayKey, int steps) async {
  final existing = await db.bodyMetricOnce(dayKey);
  final now = DateTime.now().toUtc();
  if (existing != null && existing.steps == steps) return;
  final row = existing == null
      ? BodyMetric(id: dayKey, updatedAt: now).copyWith(
          steps: Value(steps),
          syncedAt: const Value(null),
        )
      : existing.copyWith(
          steps: Value(steps),
          updatedAt: now,
          syncedAt: const Value(null),
        );
  await db.bodyMetrics.insertOnConflictUpdate(row.toCompanion(false));
}

