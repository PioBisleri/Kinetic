import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/sync/sync_codec.dart';
import 'package:kinetic/core/sync/sync_encryption.dart';
import 'package:kinetic/core/sync/sync_engine.dart';
import 'package:kinetic/core/sync/sync_key_service.dart';
import 'package:kinetic/core/sync/sync_transport.dart';
import 'package:kinetic/features/profile/body_metric_log.dart';

/// In-memory stand-in for the Supabase remote — a trimmed copy of the fake
/// in `sync_engine_test.dart` with just what `engine.sync` needs here.
class FakeSyncTransport implements SyncTransport {
  final tables = <String, List<Map<String, dynamic>>>{};

  List<Map<String, dynamic>> _rows(String table) =>
      tables.putIfAbsent(table, () => []);

  @override
  Future<void> upsert(String table, List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      _rows(table).add({...row, 'user_id': 'user-1'});
    }
  }

  @override
  Future<void> replaceChildren(
    String table,
    String parentColumn,
    List<String> parentIds,
    List<Map<String, dynamic>> rows,
  ) async {
    _rows(table).removeWhere((r) => parentIds.contains(r[parentColumn]));
    for (final row in rows) {
      _rows(table).add({...row, 'user_id': 'user-1'});
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchChanged(
    String table, {
    required DateTime since,
  }) async {
    return [
      for (final r in List<Map<String, dynamic>>.of(_rows(table)))
        if (DateTime.parse(r['updated_at'] as String).isAfter(since))
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
      for (final r in List<Map<String, dynamic>>.of(_rows(table)))
        if (parentIds.contains(r[parentColumn]))
          Map<String, dynamic>.from(r)..remove('user_id'),
    ];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase dbA;
  late AppDatabase dbB;
  late FakeSyncTransport remote;

  SyncEngine engineFor(AppDatabase db) =>
      SyncEngine(db: db, transport: remote, recompute: (_) async {});

  setUp(() {
    dbA = AppDatabase.forTesting(NativeDatabase.memory());
    dbB = AppDatabase.forTesting(NativeDatabase.memory());
    remote = FakeSyncTransport();
  });

  tearDown(() async {
    SyncCodec.apply(null); // never leak a codec between tests
    await dbA.close();
    await dbB.close();
  });

  group('codec wiring (Round 9)', () {
    test('apply(key) encrypts pushed rows — format 2, plaintext columns gone',
        () async {
      await logBodyWeight(dbA, 82.5, now: DateTime(2026, 10, 17, 9));
      final key =
          await SyncKeyService.deriveKey(passphrase: 'test-pass', userId: 'user-1');
      SyncCodec.apply(key);

      await engineFor(dbA).sync(
        since: DateTime.now().toUtc().subtract(const Duration(days: 1)),
      );

      final rows = remote.tables['body_metrics']!;
      expect(rows, hasLength(1));
      expect(rows.single['format'], SyncEncryption.formatEncrypted);
      expect(rows.single['payload'], isA<String>());
      expect(rows.single['payload'], isNotEmpty);
      // Encrypted-at-rest: the weight column must not leak into the wire row.
      expect(rows.single['weight_kg'], isNull);
      // Filters stay plaintext for the LWW/cursor queries.
      expect(rows.single['id'], isA<String>());
      expect(rows.single['updated_at'], isA<String>());
    });

    test('same passphrase on a second device decrypts the pull', () async {
      await logBodyWeight(dbA, 82.5, now: DateTime(2026, 10, 17, 9));
      SyncCodec.apply(
          await SyncKeyService.deriveKey(passphrase: 'test-pass', userId: 'user-1'));
      await engineFor(dbA).sync(
        since: DateTime.now().toUtc().subtract(const Duration(days: 1)),
      );

      SyncCodec.apply(
          await SyncKeyService.deriveKey(passphrase: 'test-pass', userId: 'user-1'));
      final result = await engineFor(dbB).sync(
        since: DateTime.now().toUtc().subtract(const Duration(days: 1)),
      );
      expect(result.pulled, 1);

      final row = await (dbB.bodyMetrics.select()
            ..where((b) => b.id.equals('2026-10-17')))
          .getSingleOrNull();
      expect(row?.weightKg, 82.5);
    });

    test('decode refuses a format-2 row while no key is applied', () async {
      final key =
          await SyncKeyService.deriveKey(passphrase: 'test-pass', userId: 'user-1');
      final encrypted = await SyncEncryption(key)
          .encryptRow({'id': 'x', 'weight_kg': 80.0}, const {});
      SyncCodec.apply(null);

      expect(
        () => SyncCodec.decode(encrypted, table: 'body_metrics'),
        throwsA(isA<FormatException>()),
      );
    });

    test('rotate: after re-apply the old ciphertext is refused', () async {
      final k1 =
          await SyncKeyService.deriveKey(passphrase: 'pass-one', userId: 'user-1');
      final k2 =
          await SyncKeyService.deriveKey(passphrase: 'pass-two', userId: 'user-1');
      final old = await SyncEncryption(k1)
          .encryptRow({'id': 'x', 'weight_kg': 80.0}, const {});

      SyncCodec.apply(k2);
      await expectLater(
        SyncCodec.decode(old, table: 'body_metrics'),
        throwsA(isA<Object>()),
      );
    });
  });

  group('plaintext fallback (Round 9)', () {
    test('apply(null) pushes plaintext rows without a format column', () async {
      await logBodyWeight(dbA, 80.0, now: DateTime(2026, 10, 17, 9));
      SyncCodec.apply(null);

      await engineFor(dbA).sync(
        since: DateTime.now().toUtc().subtract(const Duration(days: 1)),
      );

      final row = remote.tables['body_metrics']!.single;
      expect(row['format'], isNull);
      expect(row['weight_kg'], 80.0);
    });
  });
}
