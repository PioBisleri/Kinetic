import 'package:drift/drift.dart' show ValueSerializer;

import 'sync_encryption.dart';

/// Wire format for Phase 7 sync:
///
/// * column keys are snake_case (remote Postgres convention),
/// * `DateTime` values are UTC ISO-8601 strings (PostgREST `timestamptz`),
/// * local-only bookkeeping (`syncedAt`) and the local placeholder
///   `userId = 'local'` never leave the device — the transport injects the
///   real auth uid as `user_id`, and decode forces `userId` back to `local`.
///
/// Drift's default serializer writes DateTimes as unix epoch millis; the
/// remote schema uses `timestamptz`, so we override it.
///
/// Phase 10: when [encryption] is set, non-filter columns are encrypted
/// into a `payload` column (AES-256-GCM). Filter columns (`id`,
/// `updated_at`, `user_id`, parent FKs) stay plaintext for PostgREST.
const SyncValueSerializer syncValueSerializer = SyncValueSerializer();

class SyncValueSerializer extends ValueSerializer {
  const SyncValueSerializer();

  @override
  dynamic toJson<T>(T value) {
    if (value is DateTime) return value.toUtc().toIso8601String();
    return value;
  }

  @override
  T fromJson<T>(dynamic json) {
    if (json == null) return null as T;
    final probe = <T>[];
    if (probe is List<DateTime?>) {
      if (json is int) {
        return DateTime.fromMillisecondsSinceEpoch(json, isUtc: true) as T;
      }
      return DateTime.parse(json.toString()).toUtc() as T;
    }
    if (probe is List<double?> && json is int) return json.toDouble() as T;
    return json as T;
  }
}

class SyncCodec {
  SyncCodec._();

  static const ValueSerializer serializer = syncValueSerializer;

  /// Set once at app startup when sync encryption is enabled. When null,
  /// encode/decode behave as plaintext (Phase 7 behavior).
  static SyncEncryption? encryption;

  /// Local `DataClass.toJson` map → wire row (snake_case, no local-only keys).
  ///
  /// When [encryption] is set and [table] is known, non-filter columns are
  /// encrypted into a `payload` column.
  static Future<Map<String, dynamic>> encode(
    Map<String, dynamic> json, {
    String? table,
  }) async {
    final out = <String, dynamic>{};
    json.forEach((key, value) {
      // Local bookkeeping + the placeholder uid never cross the wire; the
      // transport injects the real auth uid as `user_id`.
      if (key == 'syncedAt' || key == 'userId') return;
      out[_snake(key)] = value;
    });
    if (encryption == null || table == null) return out;
    final filterCols = SyncEncryption.filterColumns[table] ?? const {};
    return encryption!.encryptRow(out, filterCols);
  }

  /// Wire row → local `DataClass.fromJson` map.
  ///
  /// The transport already strips the auth `user_id`; [userId] re-injects the
  /// local placeholder for tables whose data class requires a non-null uid.
  ///
  /// When [encryption] is set, the `payload` column is decrypted first.
  static Future<Map<String, dynamic>> decode(
    Map<String, dynamic> row, {
    String? userId,
    String? table,
  }) async {
    final decrypted =
        encryption == null ? row : await encryption!.decryptRow(row);
    final out = <String, dynamic>{};
    decrypted.forEach((key, value) {
      if (key == 'user_id') return;
      out[_camel(key)] = value;
    });
    if (userId != null) out['userId'] = userId;
    return out;
  }

  static String _snake(String key) => key
      .replaceAllMapped(
        RegExp('([a-z0-9])([A-Z])'),
        (m) => '${m[1]}_${m[2]}',
      )
      .toLowerCase();

  static String _camel(String key) {
    final parts = key.split('_');
    if (parts.length == 1) return key;
    return parts.first +
        parts.skip(1).map((p) => p.isEmpty ? p : p[0].toUpperCase() + p.substring(1)).join();
  }
}
