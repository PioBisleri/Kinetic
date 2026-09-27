import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/database/seed_service.dart';
import 'package:kinetic/features/analytics/application/landmark_store.dart';
import 'package:kinetic/features/analytics/domain/volume_landmarks.dart';

/// Round 6 volume landmarks: the curated defaults cover the catalog,
/// the band math is pure, and the override store wins or resets cleanly.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('defaults', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await SeedService(db).ensureSeeded();
    });

    tearDown(() => db.close());

    test('cover every gradeable muscle in the catalog exactly once',
        () async {
      final muscles = await db.muscleGroups.select().get();
      // Leaves = children plus the shared chest row; the parent-only
      // groups (back/shoulders/arms/core/legs) are rollups, and cardio
      // has no gradeable standard.
      final leaves = {
        for (final m in muscles)
          if (m.parentId != null || m.id == 'chest') m.id,
      }..remove('cardio');
      expect(leaves, landmarkDefaults.keys.toSet());
    });

    test('every default is an ordered, sheet-valid triple', () {
      for (final e in landmarkDefaults.entries) {
        expect(e.value.isValid, isTrue, reason: e.key);
      }
    });
  });

  group('band math', () {
    const chest = Landmark(mev: 8, mav: 18, mrv: 22);

    test('zones classify below / sweet spot / diminishing / over', () {
      expect(landmarkZone(0, chest), LandmarkZone.belowMev);
      expect(landmarkZone(7, chest), LandmarkZone.belowMev);
      // Hitting MEV counts as productive; sitting at MRV is still
      // recoverable — only exceeding it is over.
      expect(landmarkZone(8, chest), LandmarkZone.productive);
      expect(landmarkZone(18, chest), LandmarkZone.productive);
      expect(landmarkZone(19, chest), LandmarkZone.aboveMav);
      expect(landmarkZone(22, chest), LandmarkZone.aboveMav);
      expect(landmarkZone(23, chest), LandmarkZone.aboveMrv);
      expect(landmarkZone(100, chest), LandmarkZone.aboveMrv);
    });

    test('marker fraction runs on a 0..1.25 × MRV track, clamped', () {
      expect(landmarkScaleEnd(chest), closeTo(27.5, 1e-9));
      expect(markerFraction(0, chest), 0);
      expect(markerFraction(11, chest), closeTo(11 / 27.5, 1e-9));
      expect(markerFraction(-4, chest), 0); // defensive: never negative
      expect(markerFraction(1000, chest), 1); // and never off-track
    });

    test('fractions split the track at each landmark', () {
      final (mevF, mavF, mrvF) = landmarkFractions(chest);
      expect(mevF, closeTo(8 / 27.5, 1e-9));
      expect(mavF, closeTo(18 / 27.5, 1e-9));
      expect(mrvF, closeTo(22 / 27.5, 1e-9));
      expect(mevF, lessThan(mavF));
      expect(mavF, lessThan(mrvF));
      expect(mrvF, lessThan(1)); // the over-MRV zone stays plottable
    });
  });

  group('override store', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await SeedService(db).ensureSeeded();
    });

    tearDown(() => db.close());

    test('edits replace the default and reset brings it back', () async {
      final store = LandmarkStore(db);
      // Nothing edited → pure defaults.
      expect(LandmarkStore.effective(const {})['chest'],
          landmarkDefaults['chest']);

      await store.save('chest', const Landmark(mev: 10, mav: 20, mrv: 25));
      var overrides = await db.volumeLandmarks.select().get();
      expect(overrides, hasLength(1)); // upsert, not append

      final effective =
          LandmarkStore.effective({for (final v in overrides) v.muscleId: v});
      expect(effective['chest']!.mev, 10);
      expect(effective['chest']!.mav, 20);
      expect(effective['chest']!.mrv, 25);
      // Muscles without an edit keep their default.
      expect(effective['lats'], landmarkDefaults['lats']);

      // Re-saving the same muscle stays a single row.
      await store.save('chest', const Landmark(mev: 11, mav: 21, mrv: 26));
      overrides = await db.volumeLandmarks.select().get();
      expect(overrides, hasLength(1));
      expect(overrides.single.mevSets, 11);

      await store.reset('chest');
      expect(await db.volumeLandmarks.select().get(), isEmpty);
      expect(
          LandmarkStore.effective(const {})['chest'], landmarkDefaults['chest']);
    });
  });
}
