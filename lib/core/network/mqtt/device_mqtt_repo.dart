import 'dart:async';

/// Simple DTO for subscribeJson() stream items.
class MqttJson {
  final String topic;
  final Map<String, dynamic> payload;

  const MqttJson(this.topic, this.payload);
}

/// Repository interface for app-side MQTT actions.
abstract class DeviceMqttRepo {
  bool get isConnected;

  Future<void> connect({required String userId, required String token});

  Future<void> reconnect({required String userId, required String token});

  Future<void> disconnect();

  Future<void> subscribeDevice(String deviceId);

  Future<void> unsubscribeDevice(String deviceId);

  Stream<Map<String, dynamic>> deviceStream(String deviceId);

  Future<void> publishCommand(String deviceId, String action, {Map<String, dynamic>? args});

  Stream<MqttJson> subscribeJson(String topicFilter, {int qos = 1});

  Future<void> publishJson(String topic, Map<String, dynamic> payload, {int qos = 1, bool retain = false});
}
