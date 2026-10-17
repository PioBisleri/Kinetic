import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/database.dart';
import '../../core/settings/settings.dart';
import '../../core/utils/day_key.dart';
import 'step_tracker.dart';

/// Round 9: glue between the Dart side and the native [KineticLiveService]
/// (Android foreground service owning the step sensor).
///
/// Contract (never throws — mirrors [WaterReminderService]'s guard style):
/// * [LiveActivity.apply] writes the row config + targets + today's water
///   into SharedPreferences (the old prefs are the Kotlin <-> Dart channel),
///   then starts the service (or stops it when disabled).
/// * The service rebases/counts steps and writes `live_steps*` keys back.
  /// * [LiveActivity.adoptNativeSteps] merges those into `body_metrics`
  ///   (while the service is enabled it is the steps authority; the in-app
  ///   pedometer loop keeps running and converges to the same sensor value —
  ///   see step_tracker doc).
/// * [LiveActivity.refresh] re-pushes the snapshot after water/food/weight
///   or target changes, without touching the running service.
class LiveActivity {
  /// Keyed constants — must stay in lockstep with
  /// `KineticLiveService.kt` (which prefixes them with `flutter.`).
  static const configKey = 'live_config';
  static const waterMlKey = 'live_water_ml';
  static const waterTargetKey = 'live_water_target';
  static const stepsTargetKey = 'live_steps_target';
  static const weightKgKey = 'live_weight_kg';
  static const nativeStepsKey = 'live_steps';
  static const nativeStepsDayKey = 'live_steps_day';
  static const enabledKey = 'live_enabled';

  static const _channel = MethodChannel('kinetic/live_activity');

  static String config(SettingsState settings) => jsonEncode({
        'showSteps': settings.liveShowSteps,
        'showCalories': settings.liveShowCalories,
        'showHydration': settings.liveShowHydration,
      });

  /// Persists [settings]-driven snapshot keys and starts or stops the
  /// native service. Idempotent-safe: `start` on an already-running service
  /// just re-delivers the config. Returns whether the channel answered.
  Future<bool> apply(
    AppDatabase db,
    SharedPreferences prefs,
    SettingsState settings,
  ) async {
    if (!settings.liveEnabled) {
      if (prefs.getBool(enabledKey) ?? false) {
        await prefs.setBool(enabledKey, false);
        return _invoke('stop');
      }
      return false;
    }
    final day = dayKey(DateTime.now());
    final metric = await _todayMetric(db, day);
    final weight = await _latestWeightKg(db);

    await prefs.setString(configKey, config(settings));
    await prefs.setInt(waterMlKey, metric?.waterMl ?? 0);
    await prefs.setInt(waterTargetKey, settings.waterTargetMl);
    await prefs.setInt(stepsTargetKey, settings.stepsTarget);
    if (weight != null) {
      await prefs.setDouble(weightKgKey, weight);
    }

    await prefs.setBool(enabledKey, true);
    return _invoke('start');
  }

  /// Re-push today's water/weight into prefs after a change; safe when the
  /// service is off (the keys just idle).
  Future<void> refresh(
    AppDatabase db,
    SharedPreferences prefs,
    SettingsState settings,
  ) async {
    final day = dayKey(DateTime.now());
    final metric = await _todayMetric(db, day);
    await prefs.setInt(waterMlKey, metric?.waterMl ?? 0);
    await prefs.setInt(waterTargetKey, settings.waterTargetMl);
    await prefs.setInt(stepsTargetKey, settings.stepsTarget);
    final weight = await _latestWeightKg(db);
    if (weight != null) {
      await prefs.setDouble(weightKgKey, weight);
    }
    await prefs.setString(configKey, config(settings));
    if (settings.liveEnabled) {
      await _invoke('update');
    }
  }

  /// Merges the native service's latest step count into `body_metrics` —
  /// called on app resume so the {@see setDaySteps} DB stays the source of
  /// truth. A native day key older than today means the phone crossed
  /// midnight in the background: adopt nothing (both sides rebased).
  Future<int> adoptNativeSteps(
    AppDatabase db,
    SharedPreferences prefs,
  ) async {
    final day = prefs.getString(nativeStepsDayKey) ?? '';
    if (day.isEmpty || day != dayKey(DateTime.now())) return 0;
    final steps = prefs.getInt(nativeStepsKey);
    if (steps == null) return 0;
    await setDaySteps(db, day, steps);
    return steps;
  }

  /// True when the app is exempt from battery optimization — OEMs stop
  /// even a specialUse foreground service "due to app idle" otherwise
  /// (the live notification would die minutes after the app is backgrounded).
  Future<bool> batteryExempt() => _invoke('battery-exemption');

  /// Shows the system's "allow always running?" dialog; returns the status
  /// right after the launch (the dialog answered earlier shows on resume).
  Future<bool> requestBatteryExempt() => _invoke('request-battery-exemption');

  Future<BodyMetric?> _todayMetric(AppDatabase db, String day) async {
    try {
      return await (db.bodyMetrics.select()
            ..where((b) => b.id.equals(day)))
          .getSingleOrNull();
    } catch (_) {
      return null;
    }
  }

  Future<double?> _latestWeightKg(AppDatabase db) async {
    try {
      final row = await (db.bodyMetrics.select()
            ..where((b) => b.weightKg.isNotNull())
            ..orderBy([
              (b) => OrderingTerm.desc(b.updatedAt),
            ])
            ..limit(1))
          .getSingleOrNull();
      return row?.weightKg;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _invoke(String method, [Map<String, Object?>? args]) async {
    try {
      return await _channel.invokeMethod<bool>(method, args) ?? false;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }
}

final liveActivityProvider = Provider<LiveActivity>((_) => LiveActivity());

/// Oversees [LiveActivity]: the settings-page toggle, app boot/resume, and
/// every write that changes a notification row (water, food, weight,
/// targets) lands here, then pushes a fresh snapshot or toggles the
/// native service. Same never-throw contract as [LiveActivity].
class LiveActivityController {
  LiveActivityController(this._ref);

  final Ref _ref;

  /// Boot/resume path: (re)apply config + adopt the native step count.
  Future<void> reconcile() async {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);

      // Adopt first so [apply]'s snapshot and the DB agree on today's steps.
      await _service().adoptNativeSteps(
        _ref.read(databaseProvider),
        prefs,
      );
      await apply();
    } catch (_) {}
  }

  /// Starts or stops the service per [SettingsState.liveEnabled] and
  /// (re)applies the snapshot. Returns whether the channel answered.
  Future<bool> apply() async {
    try {
      return await _service().apply(
        _ref.read(databaseProvider),
        _ref.read(sharedPreferencesProvider),
        _ref.read(settingsProvider),
      );
    } catch (_) {
      return false;
    }
  }

  /// Snapshot-only refresh — water/food/weight/target edits call this,
  /// never [apply] (the running service must keep counting steps).
  Future<void> refresh() async {
    try {
      await _service().refresh(
        _ref.read(databaseProvider),
        _ref.read(sharedPreferencesProvider),
        _ref.read(settingsProvider),
      );
    } catch (_) {}
  }

  LiveActivity _service() => _ref.read(liveActivityProvider);
}

final liveActivityControllerProvider = Provider<LiveActivityController>(
  (ref) => LiveActivityController(ref),
);
