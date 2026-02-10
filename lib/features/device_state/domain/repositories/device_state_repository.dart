import 'package:oshmobile/core/network/mqtt/protocol/v1/device_state_models.dart';

abstract class DeviceStateRepository {
  /// Fetch current device state snapshot via JSON-RPC get.
  Future<DeviceStatePayload> fetch();

  /// Send device.set (not allowed by FW, expected to return NotAllowed).
  Future<void> set({String? reqId});

  /// Send device.patch (not allowed by FW, expected to return NotAllowed).
  Future<void> patch({String? reqId});

  /// Stream of retained device state notifications.
  Stream<DeviceStatePayload> watchState();
}
