import 'dart:convert';
import 'dart:typed_data';

import 'package:oshmobile/features/ble_provisioning/data/crypto/ble_secure_codec.dart';

class DevBleSecureCodec implements BleSecureCodec {
  final Uint8List _keyBytes;

  DevBleSecureCodec(String secureCode) : _keyBytes = _normalizeKey(secureCode);

  static Uint8List _normalizeKey(String secureCode) {
    final bytes = utf8.encode(secureCode);
    final result = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      result[i] = i < bytes.length ? bytes[i] : 0;
    }
    return result;
  }

  @override
  String encode(Map<String, dynamic> inner) {
    final plainJson = jsonEncode(inner);

    final transport = <String, dynamic>{
      'nonce': 'dev_nonce',
      'cipher': plainJson,
    };

    return jsonEncode(transport);
  }

  @override
  Map<String, dynamic> decode(String transportJson) {
    final decoded = jsonDecode(transportJson) as Map<String, dynamic>;
    final cipher = decoded['cipher'] as String? ?? '';

    final inner = jsonDecode(cipher);
    return inner as Map<String, dynamic>;
  }
}
