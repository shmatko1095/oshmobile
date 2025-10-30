/// Topic builder dedicated to Schedule feature.
/// Adjust paths to match your device firmware.
class ScheduleTopics {
  ScheduleTopics(this.tenantId);

  final String tenantId;

  // Reported shadow snapshot (retained JSON)
  String reported(String deviceId) => 'v1/tenants/$tenantId/devices/$deviceId/shadow/schedule/reported';

  // Ask device to publish current snapshot
  String getReq(String deviceId) => 'v1/tenants/$tenantId/devices/$deviceId/shadow/schedule/get';

  // Desired changes (full replace or patch, decided by firmware)
  String desired(String deviceId) => 'v1/tenants/$tenantId/devices/$deviceId/shadow/schedule/desired';
}
