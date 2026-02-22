import 'package:oshmobile/core/network/mqtt/device_topics_v1.dart';
import 'package:oshmobile/features/sensors/data/sensors_jsonrpc_codec.dart';

class SensorsTopics {
  static String get domain => SensorsJsonRpcCodec.domain;

  SensorsTopics(this._topics);

  final DeviceMqttTopicsV1 _topics;

  String cmd(String deviceSn) => _topics.cmd(deviceSn, domain);

  String rsp(String deviceSn) => _topics.rsp(deviceSn);

  String state(String deviceSn) => _topics.state(deviceSn, domain);

  String evt(String deviceSn) => _topics.evt(deviceSn, domain);
}
