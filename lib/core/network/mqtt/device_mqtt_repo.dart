import 'dart:async';

import 'package:meta/meta.dart';

/// Connection state as seen by the transport.
///
/// Keep this enum UI-agnostic: it is used by session-scoped cubits
/// to reflect *real* connection status.
enum DeviceMqttConnState {
  disconnected,
  connecting,
  connected,
}

/// Transport connection event.
///
/// [error] is best-effort and may be null even for unexpected disconnects.
@immutable
class DeviceMqttConnEvent {
  final DeviceMqttConnState state;
  final Object? error;
  final DateTime at;

  DeviceMqttConnEvent({
    required this.state,
    this.error,
    DateTime? at,
  }) : at = at ?? DateTime.now();
}

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

  /// Emits transport connection state changes.
  ///
  /// This stream never throws. It is safe to listen for the whole session.
  Stream<DeviceMqttConnEvent> get connEvents;

  Future<void> connect({required String userId, required String token});

  Future<void> reconnect({required String userId, required String token});

  Future<void> disconnect();

  Future<void> disposeSession();

  Stream<MqttJson> subscribeJson(String topicFilter, {int qos = 1});

  Future<void> publishJson(String topic, Map<String, dynamic> payload, {int qos = 1, bool retain = false});
}
