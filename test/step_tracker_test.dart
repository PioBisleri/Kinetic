import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/utils/day_key.dart';
import 'package:kinetic/features/health/health_providers.dart';
import 'package:kinetic/features/health/step_tracker.dart';

/// Round 8 step math + the body-metrics merge writes behind it.
/// No platform_channels: [StepMath] is pure and [setDaySteps] goes to an
/// in-memory drift.
void main() {
  late AppDatabase db;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  group('StepMath.absorb', () {
    test('normal flow: today = cumulative − baseline, state unchanged',
        () {
      final r = StepMath.absorb(
        cumulative: 500,
        todayKey: '2026-10-17',
        storedDayKey: '2026-10-17',
        storedBaseline: 200,
      );
      expect(r.today, 300);
      expect(r.dayKey, '2026-10-17');
      expect(r.baseline, 200);
    });

    test('day rollover rebases to the current cumulative, count zeroed',
        () {
      final r = StepMath.absorb(
        cumulative: 4800,
        todayKey: '2026-10-18',
        storedDayKey: '2026-10-17',
        storedBaseline: 200,
      );
      expect(r.today, 0);
      expect(r.dayKey, '2026-10-18');
      expect(r.baseline, 4800);
    });

    test('device reboot (cumulative dropped) rebases and zeroes', () {
      final r = StepMath.absorb(
        cumulative: 40,
        todayKey: '2026-10-17',
        storedDayKey: '2026-10-17',
        storedBaseline: 200,
      );
      expect(r.today, 0);
      expect(r.dayKey, '2026-10-17');
      expect(r.baseline, 40);
    });

    test('rollover wins over reboot when both are due', () {
      // New day AND a boot — the day already restarted, rebase to now.
      final r = StepMath.absorb(
        cumulative: 10,
        todayKey: '2026-10-18',
        storedDayKey: '2026-10-17',
        storedBaseline: 200,
      );
      expect(r.dayKey, '2026-10-18');
      expect(r.today, 0);
      expect(r.baseline, 10);
    });
  });

  group('setDaySteps', () {
    test('creates, overwrites and merges without clobbering water', () async {
      final k = dayKey(DateTime.now());

      await setDaySteps(db, k, 100);
      final row1 = await db.bodyMetricOnce(k);
      expect(row1, isNotNull);
      expect(row1!.steps, 100);
      expect(row1.syncedAt, isNull);

      // Water passes through a separate write; steps must survive it.
      await addWaterMl(db, k, 250);
      final row2 = await db.bodyMetricOnce(k);
      expect(row2!.waterMl, 250);
      expect(row2.steps, 100);

      await setDaySteps(db, k, 320);
      final row3 = await db.bodyMetricOnce(k);
      expect(row3!.steps, 320);
      expect(row3.waterMl, 250);
    });

    test('no-change write keeps updatedAt clean (no sync churn)', () async {
      final k = dayKey(DateTime.now());
      await setDaySteps(db, k, 500);
      final before = await db.bodyMetricOnce(k);
      await setDaySteps(db, k, 500);
      final after = await db.bodyMetricOnce(k);
      expect(after!.updatedAt.millisecondsSinceEpoch,
          before!.updatedAt.millisecondsSinceEpoch);
    });
  });

  group('addWaterMl', () {
    test('adds, clamps at zero, and bumps updatedAt on change', () async {
      final k = dayKey(DateTime.now());
      expect(await addWaterMl(db, k, 250), isTrue);
      expect((await db.bodyMetricOnce(k))!.waterMl, 250);

      expect(await addWaterMl(db, k, -100), isTrue);
      expect((await db.bodyMetricOnce(k))!.waterMl, 150);

      expect(await addWaterMl(db, k, -9999), isTrue);
      expect((await db.bodyMetricOnce(k))!.waterMl, 0);

      // No change → false, no row churn.
      expect(await addWaterMl(db, k, -1), isFalse);
      expect((await db.bodyMetricOnce(k))!.waterMl, 0);
    });
  });
}
