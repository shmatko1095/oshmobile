/// MQTT topic builder for OSH v1 protocol.
/// Versioned class name keeps room for future protocol revisions.
///
/// Base:
///   v1/tenants/<tenant>/devices/<deviceId>
///
/// Channels:
///   cmd/<domain>     (downlink: app/cloud -> device)
///   rsp             (uplink: device -> app/cloud, JSON-RPC responses)
///   evt/<domain>     (uplink: device -> app/cloud, non-retained)
///   state/<domain>   (uplink: device -> app/cloud, retained)
class DeviceMqttTopicsV1 {
  final String tenantId;

  const DeviceMqttTopicsV1(this.tenantId);

  String base(String deviceId) => 'v1/tenants/$tenantId/devices/$deviceId';

  String cmd(String deviceId, String domain) => '${base(deviceId)}/cmd/$domain';

  String rsp(String deviceId) => '${base(deviceId)}/rsp';

  String evt(String deviceId, String domain) => '${base(deviceId)}/evt/$domain';

  String state(String deviceId, String domain) => '${base(deviceId)}/state/$domain';
}
