import 'package:oshmobile/core/network/mqtt/device_topics_v1.dart';
import 'package:oshmobile/features/schedule/data/schedule_jsonrpc_codec.dart';

/// Topic builder dedicated to the Schedule feature (JSON-RPC).
///
/// Firmware contract (schedule@1):
/// - Device subscribes to `cmd(deviceId)` and handles JSON-RPC get/set/patch.
/// - Device publishes JSON-RPC responses to `rsp(deviceId)`.
/// - Device publishes retained state notifications to `state(deviceId)`.
class ScheduleTopics {
  static String get domain => ScheduleJsonRpcCodec.domain;

  ScheduleTopics(this._topics);

  final DeviceMqttTopicsV1 _topics;

  /// JSON-RPC request topic for schedule domain.
  String cmd(String deviceId) => _topics.cmd(deviceId, domain);

  /// JSON-RPC responses (shared across domains).
  String rsp(String deviceId) => _topics.rsp(deviceId);

  /// Retained schedule state notifications.
  String state(String deviceId) => _topics.state(deviceId, domain);

  /// Non-retained schedule events (optional).
  String evt(String deviceId) => _topics.evt(deviceId, domain);
}
