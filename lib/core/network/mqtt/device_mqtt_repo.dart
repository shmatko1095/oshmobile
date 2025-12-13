import 'dart:async';

/// Simple DTO for subscribeJson() stream items.
class MqttJson {
  final String topic;
  final Map<String, dynamic> payload;

  const MqttJson(this.topic, this.payload);
}

/// Repository interface for app-side MQTT actions.
///
/// Semantics:
/// - connect/reconnect/disconnect are transport operations.
/// - disposeSession() is called ONLY when the login session ends (logout),
///   and must close controllers / clear state.
abstract class DeviceMqttRepo {
  bool get isConnected;

  Future<void> connect({required String userId, required String token});

  Future<void> reconnect({required String userId, required String token});

  Future<void> disconnect();

  Future<void> disposeSession();

  Stream<MqttJson> subscribeJson(String topicFilter, {int qos = 1});

  Future<void> publishJson(String topic, Map<String, dynamic> payload, {int qos = 1, bool retain = false});
}
