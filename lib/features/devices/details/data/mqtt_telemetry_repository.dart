import 'dart:async';

import 'package:oshmobile/core/network/mqtt/device_mqtt_repo.dart';
import 'package:oshmobile/features/devices/details/domain/repositories/telemetry_repository.dart';

/// MQTT implementation. Assumes your DeviceMqttRepo emits alias-keyed maps
/// in deviceStream(). If it emits raw topic-specific payloads, add a small
/// gateway to map topic -> alias before returning.
class MqttTelemetryRepositoryImpl implements TelemetryRepository {
  MqttTelemetryRepositoryImpl(this._mqtt);

  final DeviceMqttRepo _mqtt;

  @override
  Future<void> subscribe(String deviceId) => _mqtt.subscribeDevice(deviceId);

  @override
  Future<void> unsubscribe(String deviceId) => _mqtt.unsubscribeDevice(deviceId);

  @override
  Stream<Map<String, dynamic>> watchAliases(String deviceId) {
    return _mqtt.deviceStream(deviceId).map((raw) {
// If firmware already publishes alias keys, just forward.
      return Map<String, dynamic>.from(raw);
    });
  }
}
