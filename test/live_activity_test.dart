import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/settings/settings.dart';
import 'package:kinetic/core/utils/day_key.dart';
import 'package:kinetic/features/health/live_activity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _settings = SettingsState(liveEnabled: true);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SharedPreferences prefs;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    await db.close();
  });

  group('config builder', () {
    test('mirrors the three row flags', () {
      final cfg = jsonDecode(
        LiveActivity.config(
          SettingsState(
            liveEnabled: true,
            liveShowSteps: true,
            liveShowCalories: false,
            liveShowHydration: true,
          ),
        ),
      ) as Map<String, dynamic>;
      expect(cfg['showSteps'], isTrue);
      expect(cfg['showCalories'], isFalse);
      expect(cfg['showHydration'], isTrue);
    });
  });

  group('apply', () {
    test('persists snapshot keys and calls start on the channel', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('kinetic/live_activity'),
              (call) async {
        calls.add(call);
        return true;
      });
      addTearDown(() => TestDefaultBinaryMessengerBinding.instance
          .defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('kinetic/live_activity'), null));

      final answered = await LiveActivity().apply(db, prefs, _settings);

      expect(answered, isTrue);
      expect(calls, hasLength(1));
      expect(calls.single.method, 'start');
      expect(prefs.getBool(LiveActivity.enabledKey), isTrue);
      expect(prefs.getString(LiveActivity.configKey), LiveActivity.config(_settings));
      expect(prefs.getInt(LiveActivity.waterTargetKey), _settings.waterTargetMl);
      expect(prefs.getInt(LiveActivity.stepsTargetKey), _settings.stepsTarget);
      expect(prefs.getInt(LiveActivity.waterMlKey), 0);
    });

    test('disabled → stop on the channel and enabled=false', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('kinetic/live_activity'),
              (call) async {
        calls.add(call);
        return true;
      });
      addTearDown(() => TestDefaultBinaryMessengerBinding.instance
          .defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('kinetic/live_activity'), null));
      await prefs.setBool(LiveActivity.enabledKey, true);

      final answered = await LiveActivity()
          .apply(db, prefs, SettingsState(liveEnabled: false));

      expect(answered, isTrue);
      expect(calls.single.method, 'stop');
      expect(prefs.getBool(LiveActivity.enabledKey), isFalse);
    });

    test('missing channel → never throws, answered false', () async {
      final answered = await LiveActivity().apply(db, prefs, _settings);
      expect(answered, isFalse);
      // Prefs and config were still written — arm-first contract.
      expect(prefs.getBool(LiveActivity.enabledKey), isTrue);
      expect(prefs.getString(LiveActivity.configKey), LiveActivity.config(_settings));
    });
  });

  group('refresh', () {
    test('rewrites targets + config; no channel call when disabled', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('kinetic/live_activity'),
              (call) async {
        calls.add(call);
        return true;
      });
      addTearDown(() => TestDefaultBinaryMessengerBinding.instance
          .defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('kinetic/live_activity'), null));

      await LiveActivity().refresh(
        db,
        prefs,
        SettingsState(liveEnabled: false, stepsTarget: 9999),
      );
      expect(prefs.getInt(LiveActivity.stepsTargetKey), 9999);
      expect(calls, isEmpty);
    });
  });

  group('adoptNativeSteps', () {
    test('merges the native count into body_metrics', () async {
      final day = dayKey(DateTime.now());
      await prefs.setString(LiveActivity.nativeStepsDayKey, day);
      await prefs.setInt(LiveActivity.nativeStepsKey, 4210);

      final adopted = await LiveActivity().adoptNativeSteps(db, prefs);
      expect(adopted, 4210);

      final row = await (db.bodyMetrics.select()..where((b) => b.id.equals(day)))
          .getSingleOrNull();
      expect(row?.steps, 4210);
    });

    test('stale native day (midnight in background) adopts nothing', () async {
      await prefs.setString(LiveActivity.nativeStepsDayKey, '2000-01-01');
      await prefs.setInt(LiveActivity.nativeStepsKey, 4210);

      final adopted = await LiveActivity().adoptNativeSteps(db, prefs);
      expect(adopted, 0);
    });

    test('no native data at all adopts nothing', () async {
      expect(await LiveActivity().adoptNativeSteps(db, prefs), 0);
    });
  });
}
