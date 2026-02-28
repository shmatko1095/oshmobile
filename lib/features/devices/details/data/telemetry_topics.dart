import 'package:oshmobile/core/contracts/device_runtime_contracts.dart';
import 'package:oshmobile/core/network/mqtt/device_topics_v1.dart';

class TelemetryTopics {
  TelemetryTopics(
    this._topics, [
    DeviceRuntimeContracts? contracts,
  ]) : _contracts = contracts ?? DeviceRuntimeContracts();

  final DeviceMqttTopicsV1 _topics;
  final DeviceRuntimeContracts _contracts;

  String get domain => _contracts.telemetry.methodDomain;

  String cmd(String deviceId) => _topics.cmd(deviceId, domain);

  String rsp(String deviceId) => _topics.rsp(deviceId);

  String stateTelemetry(String deviceId) => _topics.state(deviceId, domain);
}
