import 'package:oshmobile/core/network/mqtt/device_topics_v1.dart';

class DeviceContractsTopics {
  static const String domain = 'contracts';
  static const String schema = 'contracts@1';
  static const String methodState = 'contracts.state';
  static const String methodGet = 'contracts.get';

  DeviceContractsTopics(this._topics);

  final DeviceMqttTopicsV1 _topics;

  String cmd(String deviceSn) => _topics.cmd(deviceSn, domain);

  String rsp(String deviceSn) => _topics.rsp(deviceSn);

  String state(String deviceSn) => _topics.state(deviceSn, domain);
}
