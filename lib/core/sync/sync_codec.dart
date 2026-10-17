import 'package:cryptography/cryptography.dart' show SecretKey;
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

  /// Set each sync cycle from the derived passphrase key (see
  /// `syncEncryptionKeyProvider`). When null, encode/decode behave as
  /// plaintext (Phase 7 behavior).
  static SyncEncryption? encryption;

  /// Wire [SyncCodec.encryption] up from a derived key — the single
  /// place an instance is created outside of tests. A null [key] clears
  /// the codec back to plaintext.
  static void apply(SecretKey? key) {
    encryption = key == null ? null : SyncEncryption(key);
  }

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
  ///
  /// A `format = 2` row arriving while no key is usable is *refused*, not
  /// passed through: it would otherwise feed `fromJson` a columnless row and
  /// stall the pull cursor forever. The controller surfaces the throw as
  /// `lastError`.
  static Future<Map<String, dynamic>> decode(
    Map<String, dynamic> row, {
    String? userId,
    String? table,
  }) async {
    final Map<String, dynamic> decrypted;
    if (encryption == null) {
      final format = row['format'];
      if (format is num && format.toInt() == SyncEncryption.formatEncrypted) {
        throw const FormatException(
          'encrypted sync payload but no sync passphrase is set',
        );
      }
      decrypted = row;
    } else {
      decrypted = await encryption!.decryptRow(row);
    }
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
