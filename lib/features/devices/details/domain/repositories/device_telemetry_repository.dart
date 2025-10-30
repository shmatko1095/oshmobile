abstract class DeviceTelemetryRepository {
  /// Subscribe to MQTT topics needed for telemetry of a single device.
  Future<void> subscribe(String deviceId);

  /// Unsubscribe from telemetry topics of a single device.
  Future<void> unsubscribe(String deviceId);

  /// Broadcast stream with merged telemetry map for a single device.
  Stream<Map<String, dynamic>> stream(String deviceId);
}
