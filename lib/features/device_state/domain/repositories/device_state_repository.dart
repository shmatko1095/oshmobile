import 'package:oshmobile/core/network/mqtt/protocol/v1/device_state_models.dart';

abstract class DeviceStateRepository {
  /// Fetch current device state snapshot via JSON-RPC get.
  Future<DeviceStatePayload> fetch();

  /// Stream of retained device state notifications.
  Stream<DeviceStatePayload> watchState();
}
