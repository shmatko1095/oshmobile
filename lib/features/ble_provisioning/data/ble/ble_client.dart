import 'dart:async';
import 'dart:typed_data';

/// Generic BLE advert with just what we need for discovery.
class BleAdvertisement {
  final String deviceId; // platform-specific device identifier
  final Map<int, Uint8List> manufacturerData; // key = companyId
  final String? localName;

  BleAdvertisement({
    required this.deviceId,
    required this.manufacturerData,
    required this.localName,
  });
}

/// Simple cross-platform BLE client abstraction so repository is testable.
abstract interface class BleClient {
  /// Scan for advertisements.
  ///
  /// Should be a broadcast stream that can be listened to multiple times.
  Stream<BleAdvertisement> scan();

  /// Connect to device and keep connection alive as long as [connectionStream]
  /// emits states. This can be implemented differently depending on plugin.
  Future<void> connect(String deviceId);

  /// Request MTU size if supported by underlying plugin.
  Future<int> requestMtu(String deviceId, int requested);

  /// Subscribe to notifications for a characteristic.
  Stream<List<int>> subscribeToCharacteristic({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
  });

  /// Write data to characteristic (with response).
  Future<void> writeToCharacteristic({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
    required Uint8List value,
  });

  /// Disconnect and cleanup.
  Future<void> disconnect(String deviceId);
}
