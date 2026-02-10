import 'package:oshmobile/core/network/mqtt/device_topics_v1.dart';

class TelemetryTopics {
  static const String domain = 'telemetry';
  static const String sensorsDomain = 'sensors';
  static const String deviceDomain = 'device';

  TelemetryTopics(this._topics);

  final DeviceMqttTopicsV1 _topics;

  String cmd(String deviceId) => _topics.cmd(deviceId, domain);

  String rsp(String deviceId) => _topics.rsp(deviceId);

  String stateTelemetry(String deviceId) => _topics.state(deviceId, domain);

  String stateSensors(String deviceId) => _topics.state(deviceId, sensorsDomain);

  String stateDevice(String deviceId) => _topics.state(deviceId, deviceDomain);

  String evtTelemetry(String deviceId) => _topics.evt(deviceId, domain);
}
