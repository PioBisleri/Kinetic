import 'package:drift/drift.dart' show ValueSerializer;

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

  /// Local `DataClass.toJson` map → wire row (snake_case, no local-only keys).
  static Map<String, dynamic> encode(Map<String, dynamic> json) {
    final out = <String, dynamic>{};
    json.forEach((key, value) {
      // Local bookkeeping + the placeholder uid never cross the wire; the
      // transport injects the real auth uid as `user_id`.
      if (key == 'syncedAt' || key == 'userId') return;
      out[_snake(key)] = value;
    });
    return out;
  }

  /// Wire row → local `DataClass.fromJson` map.
  ///
  /// The transport already strips the auth `user_id`; [userId] re-injects the
  /// local placeholder for tables whose data class requires a non-null uid.
  static Map<String, dynamic> decode(
    Map<String, dynamic> row, {
    String? userId,
  }) {
    final out = <String, dynamic>{};
    row.forEach((key, value) {
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
