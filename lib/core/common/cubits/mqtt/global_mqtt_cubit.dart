import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';
import 'package:oshmobile/core/network/mqtt/device_mqtt_repo.dart';

part 'global_mqtt_state.dart';

/// MQTT connection cubit.
/// Important: methods are best-effort and must not leak uncaught Future errors.
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
    if (isClosed) return;

    if (isConnected) {
      emit(const MqttConnected());
      return;
    }

    emit(const MqttConnecting());
    try {
      await _repo.connect(userId: userId, token: token);
      if (isClosed) return;
      emit(const MqttConnected());
    } catch (e, st) {
      // No implicit retry here (avoids double-handshake races).
      await OshCrashReporter.logNonFatal(e, st, reason: 'MQTT connect failed');
      if (isClosed) return;
      emit(MqttError(e.toString()));
    }
  }

  /// Call only when you really refreshed token/identity.
  Future<void> updateCredentials({
    required String userId,
    required String token,
  }) async {
    if (isClosed) return;

    try {
      await _repo.reconnect(userId: userId, token: token);
      if (isClosed) return;
      emit(const MqttConnected());
    } catch (e, st) {
      await OshCrashReporter.logNonFatal(e, st, reason: 'MQTT reconnect failed');
      if (isClosed) return;
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
      if (!isClosed) emit(const MqttDisconnected());
    }
  }

  @override
  Future<void> close() async {
    await disconnect();
    return super.close();
  }
}
