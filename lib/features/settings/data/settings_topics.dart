/// Topic builder dedicated to the Settings feature (shadow style).
///
/// Firmware contract (предложение):
/// - Публиковать retained снапшот настроек в `reported(deviceSn)`
///   после применения и по запросу.
/// - Когда в `getReq(deviceSn)` прилетает сообщение, девайс репаблишит
///   retained снапшот в `reported(deviceSn)`. Payload МОЖЕТ содержать
///   {"reqId": "..."}.
/// - При получении на `desired(deviceSn)` JSON с настройками девайс
///   применяет его и (желательно) снова публикует `reported(...)`.
class SettingsTopics {
  SettingsTopics(this.tenantId);

  final String tenantId;

  /// Retained JSON snapshot of settings:
  /// {
  ///   "display": {...},
  ///   "update": {...},
  ///   "meta": {
  ///     "lastAppliedSettingsReqId": "..."
  ///   }
  /// }
  String reported(String deviceSn) => 'v1/tenants/$tenantId/devices/$deviceSn/shadow/settings/reported';

  /// Ask device to (re)publish retained snapshot to `reported(deviceSn)`.
  /// Payload MAY contain {"reqId": "..."} for correlation.
  String getReq(String deviceSn) => 'v1/tenants/$tenantId/devices/$deviceSn/shadow/settings/get';

  /// Set desired settings bundle. Firmware applies and republish reported.
  /// Example payload:
  /// {
  ///   "reqId": "...",
  ///   "display": { ... },
  ///   "update":  { ... }
  /// }
  String desired(String deviceSn) => 'v1/tenants/$tenantId/devices/$deviceSn/shadow/settings/desired';

  /// Optional convenience: filter for the whole settings subtree.
  String filterAll(String deviceSn) => 'v1/tenants/$tenantId/devices/$deviceSn/shadow/settings/+';
}
