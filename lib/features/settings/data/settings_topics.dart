import 'package:oshmobile/core/contracts/device_runtime_contracts.dart';
import 'package:oshmobile/core/network/mqtt/device_topics_v1.dart';

/// Topic builder dedicated to the Settings feature (JSON-RPC).
///
/// Firmware contract (settings@1):
/// - Device subscribes to `cmd(deviceSn)` and handles JSON-RPC get/set/patch.
/// - Device publishes JSON-RPC responses to `rsp(deviceSn)`.
/// - Device publishes retained state notifications to `state(deviceSn)`.
class SettingsTopics {
  SettingsTopics(
    this._topics, [
    DeviceRuntimeContracts? contracts,
  ]) : _contracts = contracts ?? DeviceRuntimeContracts();

  final DeviceMqttTopicsV1 _topics;
  final DeviceRuntimeContracts _contracts;

  String get domain => _contracts.settings.methodDomain;

  /// JSON-RPC request topic for settings domain.
  String cmd(String deviceSn) => _topics.cmd(deviceSn, domain);

  /// JSON-RPC responses (shared across domains).
  String rsp(String deviceSn) => _topics.rsp(deviceSn);

  /// Retained settings state notifications.
  String state(String deviceSn) => _topics.state(deviceSn, domain);

  /// Non-retained settings events (optional).
  String evt(String deviceSn) => _topics.evt(deviceSn, domain);
}
