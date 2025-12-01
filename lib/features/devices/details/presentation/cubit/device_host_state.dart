import 'package:meta/meta.dart';

enum DeviceHostPhase {
  normal,
  waitingOnline,
}

@immutable
class DeviceHostState {
  final DeviceHostPhase phase;

  const DeviceHostState({this.phase = DeviceHostPhase.normal});

  bool get isWaitingOnline => phase == DeviceHostPhase.waitingOnline;

  DeviceHostState copyWith({DeviceHostPhase? phase}) {
    return DeviceHostState(phase: phase ?? this.phase);
  }
}
