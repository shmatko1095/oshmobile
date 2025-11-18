import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

/// Describes a single in-flight MQTT round-trip that expects an ACK
/// from the device (for example, a schedule save with reqId).
@immutable
class MqttCommOp {
  final String reqId;
  final String deviceSn;

  const MqttCommOp({
    required this.reqId,
    required this.deviceSn,
  });
}

/// Aggregate communication state used for UI.
/// It does NOT know anything about MQTT implementation details,
/// only that some operations are currently pending.
@immutable
class MqttCommState {
  final List<MqttCommOp> pending;
  final String? lastError;

  const MqttCommState({
    this.pending = const [],
    this.lastError,
  });

  bool get hasPending => pending.isNotEmpty;
}

class MqttCommCubit extends Cubit<MqttCommState> {
  MqttCommCubit() : super(const MqttCommState());

  /// Register a new in-flight operation.
  void start({
    required String reqId,
    required String deviceSn,
  }) {
    final current = state.pending;
    final updated = List<MqttCommOp>.from(current)
      ..removeWhere((op) => op.reqId == reqId)
      ..add(MqttCommOp(reqId: reqId, deviceSn: deviceSn));

    emit(MqttCommState(
      pending: updated,
      lastError: null,
    ));
  }

  /// Mark the operation as successfully acknowledged by the device.
  void complete(String reqId) {
    final updated = List<MqttCommOp>.from(state.pending)..removeWhere((op) => op.reqId == reqId);

    emit(MqttCommState(
      pending: updated,
      lastError: state.lastError,
    ));
  }

  /// Mark the operation as failed (publish error, timeout, etc).
  void fail(String reqId, String message) {
    final updated = List<MqttCommOp>.from(state.pending)..removeWhere((op) => op.reqId == reqId);

    emit(MqttCommState(
      pending: updated,
      lastError: message,
    ));
  }

  /// Drop all operations for the given device without error message.
  /// Useful when the UI is re-bound to another device or cubit is closed.
  void dropForDevice(String deviceSn) {
    final updated = List<MqttCommOp>.from(state.pending)..removeWhere((op) => op.deviceSn == deviceSn);

    emit(MqttCommState(
      pending: updated,
      lastError: state.lastError,
    ));
  }

  /// Clear last error while keeping pending operations.
  void clearError() {
    if (state.lastError == null) return;
    emit(MqttCommState(
      pending: state.pending,
      lastError: null,
    ));
  }
}
