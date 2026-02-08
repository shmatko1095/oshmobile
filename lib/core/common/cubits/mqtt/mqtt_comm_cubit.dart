import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

@immutable
class MqttCommOp {
  final String reqId;
  final String deviceSn;

  const MqttCommOp({
    required this.reqId,
    required this.deviceSn,
  });
}

@immutable
class MqttCommState {
  final List<MqttCommOp> pending;

  /// Last error across MQTT comm operations (used by parent UI icon).
  /// Cleared on new start and on any successful completion.
  final String? lastError;

  const MqttCommState({
    this.pending = const [],
    this.lastError,
  });

  bool get hasPending => pending.isNotEmpty;
}

class MqttCommCubit extends Cubit<MqttCommState> {
  MqttCommCubit() : super(const MqttCommState());

  void start({required String reqId, required String deviceSn}) {
    final next = List<MqttCommOp>.from(state.pending)..add(MqttCommOp(reqId: reqId, deviceSn: deviceSn));
    emit(MqttCommState(pending: next, lastError: null));
  }

  void complete(String reqId) {
    if (!state.pending.any((e) => e.reqId == reqId)) return;
    final next = state.pending.where((e) => e.reqId != reqId).toList(growable: false);
    emit(MqttCommState(pending: next, lastError: null));
  }

  void fail(String reqId, String message) {
    if (!state.pending.any((e) => e.reqId == reqId)) return;
    final next = state.pending.where((e) => e.reqId != reqId).toList(growable: false);
    emit(MqttCommState(pending: next, lastError: message));
  }

  void reset() {
    emit(MqttCommState(pending: const [], lastError: null));
  }

  void dropForDevice(String? deviceSn) {
    final next = state.pending.where((e) => e.deviceSn != deviceSn).toList(growable: false);
    emit(MqttCommState(pending: next, lastError: null));
  }
}
