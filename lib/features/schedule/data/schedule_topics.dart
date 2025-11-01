/// Topic builder dedicated to the Calendar/Schedule feature (shadow style).
/// Firmware contract:
/// - Publish retained snapshot to `reported(deviceId)` when asked or after apply.
/// - Trigger a publish of retained snapshot when a message appears at `getReq(deviceId)`.
///   The request MAY carry {"reqId": "..."} which firmware SHOULD reflect in reported payload.
/// - Apply a desired bundle when a message appears at `desired(deviceId)`.
///   Firmware SHOULD either reflect the request's "reqId" inside reported payload
///   (e.g., top-level "reqId" or meta.lastAppliedReqId) or at least republish reported.
class ScheduleTopics {
  ScheduleTopics(this.tenantId);

  final String tenantId;

  /// Retained JSON snapshot of calendar:
  /// {
  ///   "mode": "weekly",
  ///   "lists": {
  ///     "manual": [{"hh":0,"mm":0,"d":127,"min":21.0,"max":21.0}],
  ///     "antifreeze": [...],
  ///     "daily": [...],
  ///     "weekly": [...]
  ///   },
  ///   // optional echo for correlation:
  ///   "reqId": "123" | "meta": {"lastAppliedReqId":"123"}
  /// }
  String reported(String deviceId) => 'v1/tenants/$tenantId/devices/$deviceId/shadow/schedule/reported';

  /// Ask device to (re)publish the retained snapshot to `reported(deviceId)`.
  /// Payload MAY contain {"reqId": "..."} for correlation.
  String getReq(String deviceId) => 'v1/tenants/$tenantId/devices/$deviceId/shadow/schedule/get';

  /// Set desired bundle. Firmware applies and (ideally) republishes `reported(...)`.
  /// Payload shape:
  /// {"reqId":"...", "mode":"weekly", "lists":{...}}
  String desired(String deviceId) => 'v1/tenants/$tenantId/devices/$deviceId/shadow/schedule/desired';

  /// Optional convenience: a filter for the whole schedule subtree (if you need it).
  String filterAll(String deviceId) => 'v1/tenants/$tenantId/devices/$deviceId/shadow/schedule/+';
}
