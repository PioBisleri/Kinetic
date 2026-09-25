import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/database/seed_service.dart';
import 'package:kinetic/core/theme/app_theme.dart';
import 'package:kinetic/features/analytics/application/analytics_providers.dart';
import 'package:kinetic/features/analytics/domain/analytics_math.dart';
import 'package:kinetic/features/analytics/widgets/body_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // rootBundle for seeding
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await SeedService(db).ensureSeeded();
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> rollup(
    String muscle,
    DateTime day, {
    double volume = 0,
    int sets = 0,
    double best = 0,
  }) =>
      db.muscleVolumeDaily.insertOnConflictUpdate(
        MuscleVolumeDailyCompanion.insert(
          userId: 'local',
          muscleId: muscle,
          date: day,
          totalSets: Value(sets),
          volume: Value(volume),
          bestE1Rm: Value(best),
        ),
      );

  Future<Map<String, MuscleWindow>> readWindow() async {
    final sub = container.listen(muscleWindowProvider, (_, _) {});
    final window = await container.read(muscleWindowProvider.future);
    sub.close();
    return window;
  }

  test('aggregates the rolling 30-day window per muscle', () async {
    final today = dayOf(DateTime.now());
    await rollup('chest', today, volume: 4000, sets: 20, best: 70);
    await rollup('chest', addDays(today, -10),
        volume: 2500, sets: 12, best: 65);
    await rollup('chest', addDays(today, -40),
        volume: 9999, sets: 99, best: 999); // outside the window
    await rollup('quads', today, volume: 1000, sets: 5, best: 120);

    final w = await readWindow();

    expect(w.keys, containsAll(['chest', 'quads']));
    expect(w['chest']!.volumeKg, closeTo(6500, 0.001));
    expect(w['chest']!.totalSets, 32);
    expect(w['chest']!.bestE1Rm, 70);
    expect(w['chest']!.days, hasLength(2));
    expect(w['chest']!.lastTrained, today);
    final hours = w['chest']!.hoursSinceTrained(DateTime.now());
    expect(hours, greaterThanOrEqualTo(0));
    expect(hours, lessThan(24));
  });

  test('a muscle untouched for 30 days drops out of the window', () async {
    final today = dayOf(DateTime.now());
    await rollup('lats', addDays(today, -35), volume: 5000, sets: 10);

    final w = await readWindow();
    expect(w.containsKey('lats'), isFalse);
    expect(w['lats']?.hoursSinceTrained(DateTime.now()), isNull);
  });

  group('heatColorFor', () {
    test('fresh = red, mid = warm, cold = grey', () {
      expect(heatColorFor(1), AppColors.heatHot);
      expect(heatColorFor(0.5), AppColors.heatWarm);
      expect(heatColorFor(0), AppColors.heatRest);
      // clamps beyond the ends
      expect(heatColorFor(2), AppColors.heatHot);
      expect(heatColorFor(-1), AppColors.heatRest);
    });

    test('is monotonically warmer as freshness rises', () {
      // Red climbs cold → warm → hot (green dips again on the hot end).
      final f0 = heatColorFor(0.25);
      final f1 = heatColorFor(0.75);
      expect(f0.r, lessThan(f1.r)); // more red = fresher
    });
  });

  test('volumeOf sums a pair and treats missing muscles as zero', () {
    MuscleWindow window(String id, double volume) => MuscleWindow(
          muscleId: id,
          volumeKg: volume,
          totalSets: 1,
          bestE1Rm: 0,
          days: const {},
          lastTrained: null,
        );

    final windowData = {
      'chest': window('chest', 9000),
      'lats': window('lats', 800),
    };

    expect(volumeOf(windowData, ['chest']), 9000);
    expect(
      volumeOf(windowData, ['lats', 'rhomboids', 'traps']),
      800, // missing members contribute nothing
    );
    expect(volumeOf(const {}, ['chest']), 0);
  });

  // Plain test zone = real async, so the rootBundle-backed provider resolves
  // (it never completes inside a FakeAsync testWidgets body — see
  // analytics_page_test's override).
  test('balancePairsProvider parses the seed JSON via rootBundle', () async {
    final sub = container.listen(balancePairsProvider, (_, _) {});
    final pairs = await container.read(balancePairsProvider.future);
    sub.close();

    expect(pairs, hasLength(4));
    final chest = pairs.firstWhere((p) => p.name == 'Chest vs Back');
    expect(chest.aMuscles, ['chest']);
    expect(chest.bMuscles, ['lats', 'rhomboids', 'traps']);
    expect(chest.targetMin, 0.85);
    expect(chest.targetMax, 1.15);
  });
}
