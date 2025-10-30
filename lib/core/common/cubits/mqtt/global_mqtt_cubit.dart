import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:oshmobile/core/network/mqtt/device_mqtt_repo.dart';

part 'global_mqtt_state.dart';

/// Keeps the MQTT connection lifecycle independent from UI/Auth cubit.
/// You explicitly call connectWith(userId, token) when AuthAuthenticated,
/// and disconnect() on logout.
class GlobalMqttCubit extends Cubit<GlobalMqttState> {
  final DeviceMqttRepo _repo;

  GlobalMqttCubit({
    required DeviceMqttRepo mqttRepo,
  })  : _repo = mqttRepo,
        super(const MqttDisconnected());

  bool get isConnected => _repo.isConnected;

  Future<void> connectWith({
    required String userId,
    required String token,
  }) async {
    // Avoid duplicate connects
    if (isConnected) {
      emit(const MqttConnected());
    } else {
      emit(const MqttConnecting());
      try {
        await _repo.connect(userId: userId, token: token);
        emit(const MqttConnected());
      } catch (e) {
        emit(MqttError(e.toString()));
      }
    }
  }

  /// Update credentials (e.g., after token refresh).
  Future<void> updateCredentials({
    required String userId,
    required String token,
  }) async {
    try {
      await _repo.reconnect(userId: userId, token: token);
      emit(const MqttConnected());
    } catch (e) {
      emit(MqttError(e.toString()));
    }
  }

  Future<void> disconnect() async {
    try {
      await _repo.disconnect();
    } finally {
      emit(const MqttDisconnected());
    }
  }
}
