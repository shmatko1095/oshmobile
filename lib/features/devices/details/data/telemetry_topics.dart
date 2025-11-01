class TelemetryTopics {
  TelemetryTopics(this.tenantId);

  final String tenantId;

  String state(String deviceId) => 'v1/tenants/$tenantId/devices/$deviceId/state';

  /// All telemetry under device (alias after `telemetry/`).
  String telemetryAll(String deviceId) => 'v1/tenants/$tenantId/devices/$deviceId/telemetry/#';

  /// Optional service fan-out (if you use it)
  String serviceAll(String deviceId) => '/service/device/telemetry/$deviceId/#';
}
