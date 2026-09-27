import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/sync/sync_codec.dart';
import 'package:kinetic/core/sync/sync_engine.dart';
import 'package:kinetic/core/sync/sync_transport.dart';
import 'package:kinetic/features/profile/body_metric_log.dart';
import 'package:kinetic/features/routines/application/routine_repository.dart';

/// In-memory stand-in for the Supabase remote: stores wire rows exactly as
/// `SupabaseSyncTransport` would (user_id injected, snake_case keys, ISO
/// timestamps) and can fail `replaceChildren` on demand.
class FakeSyncTransport implements SyncTransport {
  FakeSyncTransport({this.userId = 'user-1'});

  final String userId;
  final tables = <String, List<Map<String, dynamic>>>{};
  bool failReplace = false;
  int upsertCalls = 0;
  int replaceCalls = 0;

  List<Map<String, dynamic>> _rows(String table) =>
      tables.putIfAbsent(table, () => []);

  @override
  Future<void> upsert(String table, List<Map<String, dynamic>> rows) async {
    upsertCalls++;
    for (final row in rows) {
      final stored = <String, dynamic>{...row, 'user_id': userId};
      final list = _rows(table);
      final idx =
          list.indexWhere((r) => r['id'] == stored['id'] && r['user_id'] == userId);
      if (idx >= 0) {
        list[idx] = stored;
      } else {
        list.add(stored);
      }
    }
  }

  @override
  Future<void> replaceChildren(
    String table,
    String parentColumn,
    List<String> parentIds,
    List<Map<String, dynamic>> rows,
  ) async {
    if (failReplace) throw Exception('network down (replaceChildren)');
    replaceCalls++;
    _rows(table).removeWhere((r) => parentIds.contains(r[parentColumn]));
    for (final row in rows) {
      _rows(table).add(<String, dynamic>{...row, 'user_id': userId});
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchChanged(
    String table, {
    required DateTime since,
  }) async {
    return [
      for (final r in _rows(table))
        if (r['user_id'] == userId &&
            DateTime.parse(r['updated_at'] as String).isAfter(since))
          Map<String, dynamic>.from(r)..remove('user_id'),
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchChildren(
    String table,
    String parentColumn,
    List<String> parentIds,
  ) async {
    return [
      for (final r in _rows(table))
        if (r['user_id'] == userId && parentIds.contains(r[parentColumn]))
          Map<String, dynamic>.from(r)..remove('user_id'),
    ];
  }
}

void main() {
  late AppDatabase dbA;
  late AppDatabase dbB;
  late FakeSyncTransport remote;
  late List<DateTime> recomputedA;
  late List<DateTime> recomputedB;

  SyncEngine engine(AppDatabase db, List<DateTime> sink) => SyncEngine(
        db: db,
        transport: remote,
        recompute: (times) async => sink.addAll(times),
      );

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    dbA = AppDatabase.forTesting(NativeDatabase.memory());
    dbB = AppDatabase.forTesting(NativeDatabase.memory());
    remote = FakeSyncTransport();
    recomputedA = [];
    recomputedB = [];
  });

  tearDown(() async {
    await dbA.close();
    await dbB.close();
  });

  var seq = 0;
  String nextId(String prefix) => '$prefix-${++seq}';

  DateTime stamp([int seconds = 0]) =>
      DateTime.now().toUtc().add(Duration(seconds: seconds));

  Future<String> insertWorkout(
    AppDatabase db, {
    String? id,
    String status = 'completed',
    String? notes,
    required DateTime updatedAt,
  }) async {
    final wid = id ?? nextId('w');
    await db.workouts.insertOnConflictUpdate(WorkoutsCompanion.insert(
      id: wid,
      userId: 'local',
      startedAt: updatedAt,
      status: Value(status),
      updatedAt: updatedAt,
      notes: Value(notes),
    ));
    return wid;
  }

  Future<void> insertSet(
    AppDatabase db, {
    required String workoutId,
    String? setId,
    String exerciseId = 'barbell-bench-press',
    double weightKg = 60,
    int reps = 5,
    DateTime? loggedAt,
    required DateTime updatedAt,
  }) async {
    await db.workoutSets.insertOnConflictUpdate(WorkoutSetsCompanion.insert(
      id: setId ?? nextId('s'),
      workoutId: workoutId,
      exerciseId: exerciseId,
      orderIndex: 0,
      weightKg: Value(weightKg),
      reps: Value(reps),
      isCompleted: const Value(true),
      loggedAt: Value(loggedAt ?? updatedAt),
      updatedAt: updatedAt,
    ));
  }

  Future<List<WorkoutSet>> setsOf(AppDatabase db, String workoutId) =>
      (db.workoutSets.select()
            ..where((s) => s.workoutId.equals(workoutId)))
          .get();

  List<Map<String, dynamic>> remoteRows(String table) =>
      remote.tables[table] ?? const [];

  group('wire codec', () {
    test('encodes camelCase keys to snake_case, drops local-only keys', () {
      final wire = SyncCodec.encode({
        'updatedAt': DateTime.utc(2026, 9, 25, 10),
        'syncedAt': DateTime.utc(2026, 9, 25, 10),
        'deletedAt': null,
        'userId': 'local',
        'bodyweightKg': 72.5,
        'primaryMuscleId': 'chest',
        'isCustom': true,
      });
      expect(wire.keys, containsAll(['updated_at', 'deleted_at']));
      expect(wire.keys, isNot(contains('synced_at')));
      expect(wire.keys, isNot(contains('user_id')));
      expect(wire['bodyweight_kg'], 72.5);
      expect(wire['primary_muscle_id'], 'chest');
      expect(wire['is_custom'], true);
    });

    test('serializes DateTimes as UTC ISO-8601 and parses them back', () {
      final iso = syncValueSerializer.toJson(DateTime.utc(2026, 9, 25, 10, 30));
      expect(iso, '2026-09-25T10:30:00.000Z');
      final back =
          syncValueSerializer.fromJson<DateTime>('2026-09-25T08:30:00+00:00');
      expect(back, DateTime.utc(2026, 9, 25, 8, 30));
      expect(back.isUtc, isTrue);
    });

    test('decodes wire rows back to camelCase and re-injects local uid', () {
      final json = SyncCodec.decode({
        'id': 'r1',
        'user_id': 'auth-uid',
        'updated_at': '2026-09-25T10:00:00Z',
        'order_index': 2,
      }, userId: 'local');
      expect(json['updated_at'], isNull);
      expect(json['updatedAt'], '2026-09-25T10:00:00Z');
      expect(json['orderIndex'], 2);
      expect(json['userId'], 'local');
      expect(json.containsKey('user_id'), isFalse);
    });
  });

  group('push', () {
    test('uploads dirty rows, strips synced_at, marks rows clean', () async {
      final t = stamp();
      final wid = await insertWorkout(dbA, updatedAt: t, notes: 'push me');
      await insertSet(dbA, workoutId: wid, updatedAt: t);

      final result = await engine(dbA, recomputedA).sync();

      expect(result.pushed, 1);
      final wireWorkout = remoteRows('workouts').single;
      expect(wireWorkout['id'], wid);
      expect(wireWorkout['user_id'], 'user-1');
      expect(wireWorkout['notes'], 'push me');
      expect(wireWorkout.containsKey('synced_at'), isFalse);
      expect(wireWorkout.containsKey('user_id'), isTrue);
      // ISO string, not epoch millis.
      expect(wireWorkout['updated_at'], isA<String>());
      expect(remoteRows('workout_sets'), hasLength(1));

      final row = await (dbA.workouts.select()
            ..where((w) => w.id.equals(wid)))
          .getSingle();
      expect(row.syncedAt, row.updatedAt);

      // Second cycle: nothing dirty → no upload at all.
      final before = remote.upsertCalls;
      final again = await engine(dbA, recomputedA).sync(since: result.startedAt);
      expect(again.pushed, 0);
      expect(remote.upsertCalls, before);
    });

    test('a row whose updatedAt == syncedAt (seeded catalog) never uploads',
        () async {
      final epoch = DateTime.utc(2020, 1, 1);
      await dbA.exercises.insertOnConflictUpdate(ExercisesCompanion.insert(
        id: 'seeded-ex',
        name: 'Seeded',
        mechanics: 'compound',
        primaryMuscleId: 'chest',
        updatedAt: epoch,
        syncedAt: Value(epoch),
      ));

      await engine(dbA, recomputedA).sync();

      expect(remoteRows('exercises'), isEmpty);
    });

    test('soft-deleted exercise travels as a tombstone', () async {
      final t = stamp();
      final id = nextId('cus');
      await dbA.exercises.insertOnConflictUpdate(ExercisesCompanion.insert(
        id: id,
        name: 'Cable Fly',
        mechanics: 'isolation',
        primaryMuscleId: 'chest',
        isCustom: const Value(true),
        ownerId: const Value('local'),
        updatedAt: t,
      ));
      await engine(dbA, recomputedA).sync(); // live baseline upstream
      await engine(dbB, recomputedB).sync(); // B has the row now

      final t2 = stamp(60);
      await (dbA.exercises.update()..where((e) => e.id.equals(id)))
          .write(ExercisesCompanion(
              deletedAt: Value(t2), updatedAt: Value(t2)));
      await engine(dbA, recomputedA).sync();
      await engine(dbB, recomputedB).sync();

      final remoteRow =
          remoteRows('exercises').singleWhere((r) => r['id'] == id);
      expect(remoteRow['deleted_at'], isNotNull);

      final onB = await (dbB.exercises.select()
            ..where((e) => e.id.equals(id)))
          .getSingle();
      expect(onB.deletedAt, isNotNull);
      expect(onB.syncedAt, onB.updatedAt);
    });
  });

  group('pull', () {
    test('workout + sets replicate to a second device, rollups retriggered',
        () async {
      final t = stamp();
      final loggedAt = DateTime.utc(2026, 9, 20, 18, 5);
      final wid = await insertWorkout(dbA, notes: 'day one', updatedAt: t);
      await insertSet(dbA, workoutId: wid, loggedAt: loggedAt, updatedAt: t);
      await insertSet(
        dbA,
        workoutId: wid,
        exerciseId: 'barbell-squat',
        weightKg: 100,
        reps: 3,
        loggedAt: loggedAt,
        updatedAt: t,
      );

      await engine(dbA, recomputedA).sync();
      await engine(dbB, recomputedB).sync();

      final onB = await (dbB.workouts.select()
            ..where((w) => w.id.equals(wid)))
          .getSingle();
      expect(onB.notes, 'day one');
      expect(onB.userId, 'local');
      final setsB = await setsOf(dbB, wid);
      expect(setsB, hasLength(2));
      expect(setsB.map((s) => s.weightKg).toSet(), {60.0, 100.0});
      // Applied rows are pre-marked clean — no echo push from B.
      expect(onB.syncedAt, onB.updatedAt);
      expect(setsB.every((s) => s.syncedAt == s.updatedAt), isTrue);
      expect(recomputedB, containsAll([loggedAt]));
    });

    test('profile replicates — including the Your data columns', () async {
      final t = stamp();
      await dbA.profiles.insertOnConflictUpdate(ProfilesCompanion.insert(
        id: 'local',
        bodyweightKg: Value(72.5),
        heightCm: Value(180),
        birthDate: Value('1996-03-04'),
        sex: Value('other'),
        bodyFatPct: Value(14.5),
        trainingGoal: Value('hypertrophy'),
        updatedAt: t,
      ));
      await engine(dbA, recomputedA).sync();
      await engine(dbB, recomputedB).sync();

      final profile = await dbB.profiles
          .select()
          .getSingle();
      expect(profile.bodyweightKg, 72.5);
      expect(profile.id, 'local');
      // Round 5 columns ride the same generic codec — no special case.
      expect(profile.heightCm, 180);
      expect(profile.birthDate, '1996-03-04');
      expect(profile.sex, 'other');
      expect(profile.bodyFatPct, 14.5);
      expect(profile.trainingGoal, 'hypertrophy');
    });

    test('weigh-ins replicate, and a later correction wins', () async {
      await logBodyWeight(dbA, 82.5, now: DateTime(2026, 9, 20));
      await logBodyWeight(dbA, 82.1, now: DateTime(2026, 9, 21));

      await engine(dbA, recomputedA).sync();
      expect(remoteRows('body_metrics'), hasLength(2));
      await engine(dbB, recomputedB).sync();

      final onB = await (dbB.bodyMetrics.select()
            ..orderBy([(m) => OrderingTerm.asc(m.id)]))
          .get();
      expect(onB, hasLength(2));
      expect(onB.map((m) => m.weightKg), [82.5, 82.1]);
      // Applied rows are pre-marked clean — no echo push from B.
      expect(onB.every((m) => m.syncedAt == m.updatedAt), isTrue);

      // B corrects the same day with a strictly newer stamp; the pull
      // gate must keep it locally, then push it so A converges.
      final t2 = DateTime.now().toUtc().add(const Duration(minutes: 1));
      await (dbB.bodyMetrics.update()
            ..where((m) => m.id.equals('2026-09-21')))
          .write(BodyMetricsCompanion(
              weightKg: const Value(81.9), updatedAt: Value(t2)));

      await engine(dbB, recomputedB).sync(); // push B's correction
      await engine(dbA, recomputedA).sync(); // A pulls the newer row

      final remoteRow = remoteRows('body_metrics')
          .singleWhere((r) => r['id'] == '2026-09-21');
      expect(remoteRow['weight_kg'], 81.9);
      final aRow = await (dbA.bodyMetrics.select()
            ..where((m) => m.id.equals('2026-09-21')))
          .getSingle();
      expect(aRow.weightKg, 81.9);
      expect(aRow.syncedAt, aRow.updatedAt);
    });

    test('last-write-wins: newer row wins in both directions', () async {
      final base = stamp();
      final id = nextId('r');
      await dbA.routines.insertOnConflictUpdate(RoutinesCompanion.insert(
        id: id,
        userId: 'local',
        name: 'Push A',
        updatedAt: base,
      )); // dirty → first sync uploads it
      await engine(dbA, recomputedA).sync();
      await engine(dbB, recomputedB).sync();

      // A edits at +1min, B edits the same routine at +2min.
      final tA = stamp(60);
      final tB = stamp(120);
      await (dbA.routines.update()..where((r) => r.id.equals(id)))
          .write(RoutinesCompanion(name: const Value('A version'), updatedAt: Value(tA)));
      await (dbB.routines.update()..where((r) => r.id.equals(id)))
          .write(RoutinesCompanion(name: const Value('B version'), updatedAt: Value(tB)));

      await engine(dbA, recomputedA).sync(); // push A's older edit
      await engine(dbB, recomputedB).sync(); // B's pull skips it, then pushes
      await engine(dbA, recomputedA).sync(); // A pulls B's newer edit

      final aRow = await (dbA.routines.select()
            ..where((r) => r.id.equals(id)))
          .getSingle();
      final bRow = await (dbB.routines.select()
            ..where((r) => r.id.equals(id)))
          .getSingle();
      expect(aRow.name, 'B version');
      expect(bRow.name, 'B version');
      expect(aRow.syncedAt, aRow.updatedAt);
    });

    test('remote tombstone applies locally; live list hides it', () async {
      final repo = RoutineRepository(dbA);
      final id = await repo.saveRoutine(name: 'Leg Day', entries: const []);
      await engine(dbA, recomputedA).sync(); // routine is dirty from save
      await engine(dbB, recomputedB).sync();
      expect(
        (await dbB.routines.select().get()).map((r) => r.id),
        contains(id),
      );

      // A deletes the routine (soft, bumps updatedAt); pin the timestamp so
      // the tombstone is strictly newer than what B already pulled.
      await repo.deleteRoutine(id);
      final tombstoneAt = stamp(60);
      await (dbA.routines.update()..where((r) => r.id.equals(id)))
          .write(RoutinesCompanion(
              deletedAt: Value(tombstoneAt), updatedAt: Value(tombstoneAt)));
      await engine(dbA, recomputedA).sync();
      await engine(dbB, recomputedB).sync();

      final onB = await (dbB.routines.select()
            ..where((r) => r.id.equals(id)))
          .getSingle();
      expect(onB.deletedAt, isNotNull);
      // The live-list query on B hides it too.
      final live = await (dbB.routines.select()
            ..where((r) => r.deletedAt.isNull()))
          .get();
      expect(live.map((r) => r.id), isNot(contains(id)));
    });

    test('in-progress workouts are not imported until they complete',
        () async {
      final t = stamp();
      final wid = await insertWorkout(dbA, status: 'active', updatedAt: t);
      await engine(dbA, recomputedA).sync();
      await engine(dbB, recomputedB).sync();
      expect(await dbB.workouts.select().get(), isEmpty);

      final done = stamp(300);
      await (dbA.workouts.update()..where((w) => w.id.equals(wid)))
          .write(WorkoutsCompanion(
              status: const Value('completed'), updatedAt: Value(done)));
      await engine(dbA, recomputedA).sync();
      await engine(dbB, recomputedB).sync();

      expect(
        (await dbB.workouts.select().get()).map((w) => w.id),
        contains(wid),
      );
    });
  });

  group('children ride parents', () {
    test('hard-deleting a set on A removes it on B', () async {
      final t = stamp();
      final wid = await insertWorkout(dbA, updatedAt: t);
      final keep = nextId('s');
      final drop = nextId('s');
      await insertSet(dbA, workoutId: wid, setId: keep, updatedAt: t);
      await insertSet(
          dbA, workoutId: wid, setId: drop, weightKg: 120, updatedAt: t);
      await engine(dbA, recomputedA).sync();
      await engine(dbB, recomputedB).sync();
      expect(await setsOf(dbB, wid), hasLength(2));

      // Mirror WorkoutSessionNotifier.deleteSet: hard delete + parent touch.
      await (dbA.workoutSets.delete()..where((s) => s.id.equals(drop))).go();
      await (dbA.workouts.update()..where((w) => w.id.equals(wid)))
          .write(WorkoutsCompanion(updatedAt: Value(stamp(60))));

      await engine(dbA, recomputedA).sync();
      await engine(dbB, recomputedB).sync();

      expect((await setsOf(dbB, wid)).map((s) => s.id), [keep]);
      // And the remote child set matches A exactly.
      expect(remoteRows('workout_sets').map((r) => r['id']), [keep]);
    });

    test('failed child replace bumps the parent so a retry converges',
        () async {
      final t = stamp();
      final wid = await insertWorkout(dbA, updatedAt: t);
      await insertSet(dbA, workoutId: wid, updatedAt: t);
      final original = (await (dbA.workouts.select()
            ..where((w) => w.id.equals(wid)))
          .getSingle())
          .updatedAt;

      remote.failReplace = true;
      await expectLater(
        engine(dbA, recomputedA).sync(),
        throwsA(isA<Exception>()),
      );

      // Parent touched → still dirty and now strictly newer, so the retry
      // pushes a row other devices will refetch children against.
      final touched = await (dbA.workouts.select()
            ..where((w) => w.id.equals(wid)))
          .getSingle();
      expect(touched.syncedAt, isNull);
      expect(touched.updatedAt.isAfter(original), isTrue);

      remote.failReplace = false;
      await engine(dbA, recomputedA).sync();

      expect(remoteRows('workout_sets'), hasLength(1));
      final settled = await (dbA.workouts.select()
            ..where((w) => w.id.equals(wid)))
          .getSingle();
      expect(settled.syncedAt, settled.updatedAt);
      expect(remoteRows('workouts').single['updated_at'],
          settled.updatedAt.toUtc().toIso8601String());
    });
  });

  group('cursor', () {
    test('since + overlap re-reads only the tail', () async {
      final t = stamp();
      final wid = await insertWorkout(dbA, notes: 'v1', updatedAt: t);
      final first = await engine(dbA, recomputedA).sync();
      expect(remote.upsertCalls, 1);

      // Second cycle with the stored cursor: nothing dirty, no re-upload.
      await engine(dbA, recomputedA).sync(since: first.startedAt);
      expect(remote.upsertCalls, 1);

      // Edit lands after the cursor → picked up on the next cycle.
      await (dbA.workouts.update()..where((w) => w.id.equals(wid)))
          .write(WorkoutsCompanion(
              notes: const Value('v2'), updatedAt: Value(stamp(60))));
      final third = await engine(dbA, recomputedA).sync(since: first.startedAt);
      expect(third.pushed, 1);
      expect(remoteRows('workouts').single['notes'], 'v2');
    });
  });
}
