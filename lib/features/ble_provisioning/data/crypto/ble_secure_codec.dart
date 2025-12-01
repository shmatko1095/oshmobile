/// Common interface for BLE secure transport codec.
abstract interface class BleSecureCodec {
  /// Encode inner JSON map into transport envelope JSON string.
  String encode(Map<String, dynamic> inner);

  /// Decode transport envelope JSON string into inner JSON map.
  Map<String, dynamic> decode(String transportJson);
}

typedef BleSecureCodecFactory = BleSecureCodec Function(String secureCode);
