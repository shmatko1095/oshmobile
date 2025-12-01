import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:oshmobile/features/ble_provisioning/data/crypto/ble_secure_codec.dart';

/// Handles AES-128-CTR encryption and JSON envelope:
/// { "nonce": "...", "cipher": "..." }
class AesCtrBleSecureCodec implements BleSecureCodec {
  final Uint8List _keyBytes; // 16 bytes

  AesCtrBleSecureCodec(String secureCode) : _keyBytes = _normalizeKey(secureCode);

  static Uint8List _normalizeKey(String secureCode) {
    // This function must ensure 16 bytes key.
    // For now we simply UTF8 encode and pad/truncate.
    final bytes = utf8.encode(secureCode);
    final result = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      result[i] = i < bytes.length ? bytes[i] : 0;
    }
    return result;
  }

  /// Encode inner JSON map into transport JSON string.
  @override
  String encode(Map<String, dynamic> inner) {
    final plain = utf8.encode(jsonEncode(inner));
    final nonce = _randomBytes(16);

    final key = enc.Key(_keyBytes);
    final iv = enc.IV(nonce);
    final aes = enc.Encrypter(enc.AES(key, mode: enc.AESMode.ctr));
    final encrypted = aes.encryptBytes(plain, iv: iv);

    final transport = <String, dynamic>{
      'nonce': base64Encode(nonce),
      'cipher': base64Encode(encrypted.bytes),
    };

    return jsonEncode(transport);
  }

  /// Decode transport JSON string into inner JSON map.
  ///
  /// Dev mode: if decryption fails, we treat `cipher` as plain JSON string.
  @override
  Map<String, dynamic> decode(String transportJson) {
    final decoded = jsonDecode(transportJson) as Map<String, dynamic>;
    final nonceB64 = decoded['nonce'] as String? ?? '';
    final cipherB64 = decoded['cipher'] as String? ?? '';

    try {
      final nonce = base64Decode(nonceB64);
      final cipherBytes = base64Decode(cipherB64);

      final key = enc.Key(_keyBytes);
      final iv = enc.IV(nonce);
      final aes = enc.Encrypter(enc.AES(key, mode: enc.AESMode.ctr));
      final plainBytes = aes.decryptBytes(enc.Encrypted(cipherBytes), iv: iv);

      final plainStr = utf8.decode(plainBytes);
      return jsonDecode(plainStr) as Map<String, dynamic>;
    } catch (_) {
      // Dev mode fallback: cipher contains plain JSON string.
      final plainStr = cipherB64;
      final inner = jsonDecode(plainStr);
      return inner as Map<String, dynamic>;
    }
  }

  static Uint8List _randomBytes(int length) {
    final rnd = Random.secure();
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = rnd.nextInt(256);
    }
    return bytes;
  }
}
