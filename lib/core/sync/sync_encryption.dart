import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Encrypts and decrypts sync payloads with AES-256-GCM.
///
/// The wire row keeps plaintext columns PostgREST filters on (`id`,
/// `updated_at`, `user_id`, parent FKs) and stores all other columns as
/// an encrypted JSON blob in `payload` (base64: nonce + ciphertext + tag).
class SyncEncryption {
  static const _nonceLength = 12; // 96 bits for GCM
  static const _formatPlaintext = 1;
  static const _formatEncrypted = 2;

  final SecretKey _key;
  final AesGcm _algorithm;

  SyncEncryption(this._key) : _algorithm = AesGcm.with256bits();

  /// Encrypt a row's non-filterable columns into a `payload` column.
  ///
  /// [filterColumns] are kept plaintext (id, updated_at, user_id, parent FKs).
  /// Returns the wire row with `payload` set and `format = 2`.
  Future<Map<String, dynamic>> encryptRow(
    Map<String, dynamic> row,
    Set<String> filterColumns,
  ) async {
    final payload = <String, dynamic>{};
    row.forEach((key, value) {
      if (filterColumns.contains(key)) return;
      if (key == 'payload' || key == 'format') return;
      payload[key] = value;
    });

    final plaintext = utf8.encode(jsonEncode(payload));
    final secretBox = await _algorithm.encrypt(plaintext, secretKey: _key);
    final blob = Uint8List.fromList([
      ...secretBox.nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);

    final out = <String, dynamic>{
      ...row,
      'payload': base64Encode(blob),
      'format': _formatEncrypted,
    };
    // Remove the encrypted columns from the top level — they live in payload.
    for (final key in payload.keys) {
      out.remove(key);
    }
    return out;
  }

  /// Decrypt a wire row's `payload` column back into the full row.
  ///
  /// Returns the original row with all columns restored. If the row is
  /// format 1 (plaintext), returns it unchanged.
  Future<Map<String, dynamic>> decryptRow(
    Map<String, dynamic> row,
  ) async {
    final format = row['format'];
    if (format == _formatPlaintext) return row;
    if (format != _formatEncrypted) return row;

    final blob = base64Decode(row['payload'] as String);
    final nonce = blob.sublist(0, _nonceLength);
    final macStart = blob.length - 16;
    final cipherText = blob.sublist(_nonceLength, macStart);
    final mac = Mac(blob.sublist(macStart));

    final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);
    final plaintext = await _algorithm.decrypt(secretBox, secretKey: _key);
    final payload = jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>;

    final out = <String, dynamic>{
      ...row,
      ...payload,
    };
    out.remove('payload');
    return out;
  }

  /// Column sets that must stay plaintext for each table.
  static const filterColumns = <String, Set<String>>{
    'profiles': {'id', 'updated_at', 'synced_at', 'deleted_at', 'user_id'},
    'exercises': {'id', 'updated_at', 'synced_at', 'deleted_at', 'user_id'},
    'exercise_muscle_map': {'exercise_id', 'muscle_id', 'user_id'},
    'routines': {'id', 'updated_at', 'synced_at', 'deleted_at', 'user_id'},
    'routine_exercises': {
      'id',
      'routine_id',
      'updated_at',
      'synced_at',
      'deleted_at',
      'user_id',
    },
    'workouts': {'id', 'updated_at', 'synced_at', 'deleted_at', 'user_id'},
    'workout_sets': {
      'id',
      'workout_id',
      'updated_at',
      'synced_at',
      'deleted_at',
      'user_id',
    },
    'body_metrics': {'id', 'updated_at', 'synced_at', 'deleted_at', 'user_id'},
  };
}
