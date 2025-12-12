import 'dart:convert';

import 'package:oshmobile/features/ble_provisioning/data/crypto/ble_secure_codec.dart';

class DevBleSecureCodec implements BleSecureCodec {
  DevBleSecureCodec(String secureCode);

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
