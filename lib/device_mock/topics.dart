/// Topic helpers to avoid typos and keep consistent structure.
class Topics {
  static String status(String tenant, String deviceId) => 'v1/tenants/$tenant/devices/$deviceId/status';

  static String reported(String tenant, String deviceId) => 'v1/tenants/$tenant/devices/$deviceId/state/reported';

  static String desired(String tenant, String deviceId) => 'v1/tenants/$tenant/devices/$deviceId/state/desired';

  static String cmdInbox(String tenant, String deviceId) => 'v1/tenants/$tenant/devices/$deviceId/cmd/inbox';

  static String cmdRespForSession(String tenant, String userId, String sessionId) =>
      'v1/tenants/$tenant/users/$userId/sessions/$sessionId/rpc/resp';

  static String telemetry(String tenant, String deviceId) => 'v1/tenants/$tenant/devices/$deviceId/telemetry';

  static String telemetryRt(String tenant, String deviceId) => 'v1/tenants/$tenant/devices/$deviceId/telemetry_rt';

  static String events(String tenant, String deviceId) => 'v1/tenants/$tenant/devices/$deviceId/events';

  static String otaProgress(String tenant, String deviceId) => 'v1/tenants/$tenant/devices/$deviceId/ota/progress';
}
