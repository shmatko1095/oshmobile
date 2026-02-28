import 'package:oshmobile/core/contracts/device_runtime_contracts.dart';
import 'package:oshmobile/core/network/mqtt/device_topics_v1.dart';

class SensorsTopics {
  SensorsTopics(
    this._topics, [
    DeviceRuntimeContracts? contracts,
  ]) : _contracts = contracts ?? DeviceRuntimeContracts();

  final DeviceMqttTopicsV1 _topics;
  final DeviceRuntimeContracts _contracts;

  String get domain => _contracts.sensors.methodDomain;

  String cmd(String deviceSn) => _topics.cmd(deviceSn, domain);

  String rsp(String deviceSn) => _topics.rsp(deviceSn);

  String state(String deviceSn) => _topics.state(deviceSn, domain);

  String evt(String deviceSn) => _topics.evt(deviceSn, domain);
}
