import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/database/seed_service.dart';
import 'package:kinetic/features/profile/body_metric_log.dart';
import 'package:kinetic/features/profile/weight_trend.dart';

/// Capture (one point per day) + the pure trend math behind the Profile
/// row and the trend sheet.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await SeedService(db).ensureSeeded();
  });

  tearDown(() => db.close());

  Future<List<BodyMetric>> rows() =>
      (db.bodyMetrics.select()..orderBy([(m) => OrderingTerm.asc(m.id)]))
          .get();

  group('logBodyWeight', () {
    test('same-day saves upsert one point, latest weight wins', () async {
      final morning = DateTime(2026, 9, 20, 8);
      await logBodyWeight(db, 82.5, now: morning);
      await logBodyWeight(db, 82.1, now: morning.add(const Duration(hours: 2)));

      final all = await rows();
      expect(all, hasLength(1));
      expect(all.single.id, '2026-09-20');
      expect(all.single.weightKg, 82.1);

      // updatedAt is the EDIT time (wall clock), not the measurement
      // time — that's what LWW and the fetch cursor both read.
      expect(all.single.updatedAt.isAfter(DateTime(2026, 9, 20).toUtc()),
          isTrue);
    });

    test('different days are separate points', () async {
      await logBodyWeight(db, 82.5, now: DateTime(2026, 9, 20));
      await logBodyWeight(db, 82.0, now: DateTime(2026, 9, 22));

      final all = await rows();
      expect(all.map((m) => m.id), ['2026-09-20', '2026-09-22']);
      expect(all.map((m) => m.weightKg), [82.5, 82.0]);
    });
  });

  group('trendPoints', () {
    final now = DateTime(2026, 9, 27, 13);

    test('keeps the 12-week window, sorted oldest first', () async {
      await logBodyWeight(db, 79, now: DateTime(2026, 6, 1)); // way out
      await logBodyWeight(db, 80, now: DateTime(2026, 7, 1)); // 88 days → out
      await logBodyWeight(db, 81, now: DateTime(2026, 8, 10)); // in
      await logBodyWeight(db, 82, now: DateTime(2026, 9, 27)); // today → in

      final pts = trendPoints(await rows(), now);
      expect(pts, hasLength(2));
      expect(pts.map((p) => p.weightKg), [81, 82]);
      expect(pts.first.day, DateTime(2026, 8, 10));
      expect(pts.first.day.isBefore(pts.last.day), isTrue);
    });

    test('a null weight is skipped rather than plotted at zero', () async {
      await db.bodyMetrics.insertOnConflictUpdate(BodyMetricsCompanion.insert(
        id: '2026-09-26',
        weightKg: const Value(null),
        updatedAt: DateTime.now().toUtc(),
      ));
      await logBodyWeight(db, 82, now: DateTime(2026, 9, 27));

      final pts = trendPoints(await rows(), now);
      expect(pts, hasLength(1));
      expect(pts.single.weightKg, 82);
    });
  });

  group('trailingAvg', () {
    test('averages the 7 days ending at each point', () async {
      await logBodyWeight(db, 80, now: DateTime(2026, 9, 20));
      await logBodyWeight(db, 84, now: DateTime(2026, 9, 23)); // within 7d
      await logBodyWeight(db, 90, now: DateTime(2026, 8, 1)); // outside

      final pts = trendPoints(await rows(), DateTime(2026, 9, 27));
      expect(trailingAvg(pts, DateTime(2026, 9, 23)), 82); // (80+84)/2
      // Nothing in the 7 days ending at a far-away day.
      expect(trailingAvg(pts, DateTime(2026, 11, 1)), isNull);
    });
  });

  group('trendDelta', () {
    test('needs two points and keeps the sign', () async {
      await logBodyWeight(db, 82, now: DateTime(2026, 9, 20));
      final one = trendPoints(await rows(), DateTime(2026, 9, 27));
      expect(trendDelta(one), isNull);

      await logBodyWeight(db, 81.5, now: DateTime(2026, 9, 24));
      final two = trendPoints(await rows(), DateTime(2026, 9, 27));
      expect(trendDelta(two), closeTo(-0.5, 1e-9)); // lost half a kilo

      await logBodyWeight(db, 83, now: DateTime(2026, 9, 26));
      final three = trendPoints(await rows(), DateTime(2026, 9, 27));
      expect(trendDelta(three), 1.0); // 82 → 83 across the window
    });
  });
}
