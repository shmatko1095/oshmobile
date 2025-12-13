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
    emit(MqttCommState(pending: next, lastError: state.lastError));
  }

  void complete(String reqId) {
    final next = state.pending.where((e) => e.reqId != reqId).toList(growable: false);
    emit(MqttCommState(pending: next, lastError: state.lastError));
  }

  void fail(String reqId, String message) {
    final next = state.pending.where((e) => e.reqId != reqId).toList(growable: false);
    emit(MqttCommState(pending: next, lastError: message));
  }

  void dropForDevice(String deviceSn) {
    final next = state.pending.where((e) => e.deviceSn != deviceSn).toList(growable: false);
    emit(MqttCommState(pending: next, lastError: state.lastError));
  }

  void reset() {
    emit(const MqttCommState(pending: [], lastError: null));
  }

  void clearError() {
    if (state.lastError == null) return;
    emit(MqttCommState(pending: state.pending, lastError: null));
  }
}
