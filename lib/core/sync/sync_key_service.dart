import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// Derives a 256-bit AES key from a user passphrase using Argon2id.
///
/// The salt is derived from the user's auth uid so it's stable across
/// devices without being stored. The passphrase never leaves the device.
class SyncKeyService {
  SyncKeyService._();

  static const _memoryKB = 65536; // 64 MB
  static const _iterations = 3;
  static const _parallelism = 4;
  static const _hashLength = 32; // 256-bit key

  static Future<SecretKey> deriveKey({
    required String passphrase,
    required String userId,
  }) async {
    final salt = await _saltFor(userId);
    final algorithm = Argon2id(
      memory: _memoryKB,
      iterations: _iterations,
      parallelism: _parallelism,
      hashLength: _hashLength,
    );
    return algorithm.deriveKey(
      secretKey: SecretKey(utf8.encode(passphrase)),
      nonce: salt,
    );
  }

  static Future<List<int>> _saltFor(String userId) async {
    final hash = await Sha256().hash(utf8.encode('kinetic-sync-v1$userId'));
    return hash.bytes;
  }
}
