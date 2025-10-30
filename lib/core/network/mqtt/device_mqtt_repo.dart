import 'dart:async';

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
}
