import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/network/mqtt/signal_command.dart';
import 'package:oshmobile/features/devices/details/domain/repositories/control_repository.dart';

class DeviceActionsState {
  final bool busy;
  final String? lastError;

  const DeviceActionsState({this.busy = false, this.lastError});
}

class DeviceActionsCubit extends Cubit<DeviceActionsState> {
  DeviceActionsCubit(this._control) : super(const DeviceActionsState());
  final ControlRepository _control;
  String _deviceSn = "";

  Future<void> bind(String deviceSn) async {
    _deviceSn = deviceSn;
  }

  Future<void> send<T>(Command<T> cmd, T value) async {
    if (state.busy) return;
    emit(const DeviceActionsState(busy: true));
    try {
      await _control.send(_deviceSn, cmd, value);
      emit(const DeviceActionsState(busy: false));
    } catch (e) {
      emit(DeviceActionsState(busy: false, lastError: e.toString()));
    }
  }
}
