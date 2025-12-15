import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';
import 'package:oshmobile/core/network/mqtt/device_mqtt_repo.dart';

part 'global_mqtt_state.dart';

/// Session-scoped MQTT cubit.
///
/// This cubit only manages connection state and delegates transport work to
/// [DeviceMqttRepo]. It is safe to call connect/disconnect multiple times;
/// operations are best-effort and won't leak errors to the Zone.
class GlobalMqttCubit extends Cubit<GlobalMqttState> {
  final DeviceMqttRepo _repo;

  late final StreamSubscription<DeviceMqttConnEvent> _connSub;

  GlobalMqttCubit({
    required DeviceMqttRepo mqttRepo,
  })  : _repo = mqttRepo,
        super(const MqttDisconnected()) {
    // Keep UI state in sync with *real* transport state.
    _connSub = _repo.connEvents.listen(_onConnEvent);
  }

  void _onConnEvent(DeviceMqttConnEvent evt) {
    if (isClosed) return;

    switch (evt.state) {
      case DeviceMqttConnState.connecting:
        // Don't override a user-visible error unless a new connect is happening.
        if (state is! MqttConnecting) emit(const MqttConnecting());
        return;
      case DeviceMqttConnState.connected:
        if (state is! MqttConnected) emit(const MqttConnected());
        return;
      case DeviceMqttConnState.disconnected:
        // If we were connected and got dropped by OS/broker, reflect it immediately.
        // (Errors are handled by feature cubits / MqttComm when they time out.)
        if (state is! MqttDisconnected) emit(const MqttDisconnected());
        return;
    }
  }

  bool get isConnected => _repo.isConnected;

  Future<void> connectWith({
    required String userId,
    required String token,
  }) async {
    // if (isClosed) return;

    if (isConnected) {
      emit(const MqttConnected());
      return;
    }

    emit(const MqttConnecting());
    try {
      await _repo.connect(userId: userId, token: token);
      // if (isClosed) return;
      emit(const MqttConnected());
    } catch (e, st) {
      // No implicit retry here (avoids double-handshake races).
      await OshCrashReporter.logNonFatal(e, st, reason: 'MQTT connect failed');
      // if (isClosed) return;
      emit(MqttError(e.toString()));
    }
  }

  /// Call only when you really refreshed token/identity.
  Future<void> updateCredentials({
    required String userId,
    required String token,
  }) async {
    // if (isClosed) return;

    try {
      await _repo.reconnect(userId: userId, token: token);
      // if (isClosed) return;
      emit(const MqttConnected());
    } catch (e, st) {
      await OshCrashReporter.logNonFatal(e, st, reason: 'MQTT reconnect failed');
      // if (isClosed) return;
      emit(MqttError(e.toString()));
    }
  }

  /// Best-effort disconnect (never throws).
  Future<void> disconnect() async {
    try {
      await _repo.disconnect();
    } catch (e, st) {
      await OshCrashReporter.logNonFatal(e, st, reason: 'MQTT disconnect failed');
    } finally {
      // if (!isClosed)
      emit(const MqttDisconnected());
    }
  }

  @override
  Future<void> close() async {
    try {
      await _connSub.cancel();
    } catch (_) {}

    await disconnect();
    return super.close();
  }
}
