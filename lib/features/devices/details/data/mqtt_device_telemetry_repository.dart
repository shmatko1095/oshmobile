import 'dart:async';

import 'package:oshmobile/core/network/mqtt/device_mqtt_repo.dart';
import 'package:oshmobile/features/devices/details/domain/repositories/device_telemetry_repository.dart';

/// Adapter over DeviceMqttRepo for Clean Architecture domain.
class MqttDeviceTelemetryRepository implements DeviceTelemetryRepository {
  final DeviceMqttRepo _mqtt;

  MqttDeviceTelemetryRepository(this._mqtt);

  @override
  Future<void> subscribe(String deviceId) => _mqtt.subscribeDevice(deviceId);

  @override
  Future<void> unsubscribe(String deviceId) => _mqtt.unsubscribeDevice(deviceId);

  @override
  Stream<Map<String, dynamic>> stream(String deviceId) => _mqtt.deviceStream(deviceId);
}
