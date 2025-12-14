import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/network/mqtt/signal_command.dart';
import 'package:oshmobile/features/devices/details/domain/repositories/control_repository.dart';

class DeviceActionsState {
  final bool busy;
  final String? lastError;

  const DeviceActionsState({this.busy = false, this.lastError});
}

/// Device-scoped: one instance per device.
class DeviceActionsCubit extends Cubit<DeviceActionsState> {
  final ControlRepository _control;
  final String deviceSn;

  DeviceActionsCubit({
    required ControlRepository control,
    required this.deviceSn,
  })  : _control = control,
        super(const DeviceActionsState());

  Future<void> send<T>(Command<T> cmd, T value) async {
    // if (isClosed) return;
    if (state.busy) return;

    emit(const DeviceActionsState(busy: true));

    try {
      await _control.send(deviceSn, cmd, value);
      // if (isClosed) return;
      emit(const DeviceActionsState(busy: false));
    } catch (e) {
      // if (isClosed) return;
      emit(DeviceActionsState(busy: false, lastError: e.toString()));
    }
  }
}
