import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/database/seed_service.dart';
import 'package:kinetic/core/settings/settings.dart';
import 'package:kinetic/features/home/home_screen_widget.dart';

/// Home-screen widget (Round 5): the stat strings the launcher shows and
/// the home_widget round-trip that persists them.
///
/// Everything runs against a fixed clock (Thu 2026-09-24) so the week
/// boundary and the streak are deterministic.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final now = DateTime(2026, 9, 24); // Thursday — week started Mon 09-21

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await SeedService(db).ensureSeeded();
  });

  tearDown(() => db.close());

  Future<void> workout(String id, DateTime at, double volumeKg) =>
      db.workouts.insertOnConflictUpdate(WorkoutsCompanion.insert(
        id: id,
        userId: 'local',
        startedAt: at,
        updatedAt: at,
        status: const Value('completed'),
        endedAt: Value(at.add(const Duration(hours: 1))),
        totalVolume: Value(volumeKg),
      ));

  test('stats: this week\'s volume, all-time streak, first routine', () async {
    // Inside the current week → counts toward the volume…
    await workout('w-now', DateTime(2026, 9, 22, 18), 300);
    // …the two older ones only feed the streak (weeks 09-14 and 09-07).
    await workout('w-old1', DateTime(2026, 9, 15, 18), 400);
    await workout('w-old2', DateTime(2026, 9, 9, 18), 500);

    // Inserted out of order — the lowest orderIndex is "next up".
    await db.routines.insertOnConflictUpdate(RoutinesCompanion.insert(
      id: 'r-z',
      userId: 'local',
      name: 'Zebra Legs',
      orderIndex: const Value(5),
      updatedAt: DateTime(2026, 9, 1),
    ));
    await db.routines.insertOnConflictUpdate(RoutinesCompanion.insert(
      id: 'r-a',
      userId: 'local',
      name: 'Push Day',
      orderIndex: const Value(0),
      updatedAt: DateTime(2026, 9, 1),
    ));

    final stats =
        await computeWidgetStats(db, now: now, unit: UnitSystem.kg);

    expect(stats.volume, '300 kg'); // 400 + 500 are last weeks
    expect(stats.streak, '3 weeks'); // 09-21 · 09-14 · 09-07
    expect(stats.routine, 'Push Day');
  });

  test('stats honour the unit setting (lbs, snapped to 0.5)', () async {
    await workout('w-now', DateTime(2026, 9, 22, 18), 300);

    final stats =
        await computeWidgetStats(db, now: now, unit: UnitSystem.lbs);

    expect(stats.volume, '661.5 lb'); // 300 kg → 661.39 lb → 661.5
  });

  test('stats: empty library shows safe defaults', () async {
    final stats =
        await computeWidgetStats(db, now: now, unit: UnitSystem.kg);

    expect(stats.volume, '0 kg');
    expect(stats.streak, '0 weeks');
    expect(stats.routine, 'No routines yet');
  });

  test('updateHomeScreenWidget saves the three keys and redraws', () async {
    await workout('w-now', DateTime(2026, 9, 22, 18), 300);

    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('home_widget'),
            (call) async {
      calls.add(call);
      return true;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('home_widget'), null));

    await updateHomeScreenWidget(db, UnitSystem.kg, now: now);

    final saves = [
      for (final c in calls)
        if (c.method == 'saveWidgetData') c,
    ];
    expect(saves, hasLength(3));
    expect(saves[0].arguments['id'], 'volume');
    expect(saves[0].arguments['data'], '300 kg');
    expect(saves[1].arguments['id'], 'streak');
    expect(saves[1].arguments['data'], '1 week');
    expect(saves[2].arguments['id'], 'routine');
    expect(saves[2].arguments['data'], 'No routines yet');

    final update = calls.singleWhere((c) => c.method == 'updateWidget');
    expect(
      (update.arguments as Map)['qualifiedAndroidName'],
      'com.kinetic.kinetic.KineticWidgetProvider',
    );
  });

  test('updateHomeScreenWidget never throws without the plugin', () async {
    // No channel handler (widget tests / platforms without the plugin):
    // the MissingPluginException must be swallowed.
    await updateHomeScreenWidget(db, UnitSystem.kg, now: now);
  });
}
