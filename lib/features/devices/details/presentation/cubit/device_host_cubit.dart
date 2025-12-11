import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_host_state.dart';
import 'package:oshmobile/features/home/presentation/bloc/home_cubit.dart';

class DeviceHostCubit extends Cubit<DeviceHostState> {
  final HomeCubit _homeCubit;
  final String _deviceId;
  Timer? _timer;

  static const int _maxChecks = 5;
  int _checksDone = 0;

  DeviceHostCubit({
    required HomeCubit homeCubit,
    required String deviceId,
  })  : _homeCubit = homeCubit,
        _deviceId = deviceId,
        super(const DeviceHostState());

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }

  void onWifiProvisioningSuccess() {
    if (state.isWaitingOnline) return;

    emit(state.copyWith(phase: DeviceHostPhase.waitingOnline));

    _timer?.cancel();
    _checksDone = 0;

    _checkOnce();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _checkOnce(),
    );
  }

  Future<void> _checkOnce() async {
    if (isClosed) return;
    await _homeCubit.updateDeviceList();

    Device? device =
        _homeCubit.userDevices.filter((d) => d.id == _deviceId).firstOrNull;
    final isOnline = device?.connectionInfo.online == true;

    if (isOnline) {
      // Device is online – stop waiting and go back to normal phase.
      _timer?.cancel();
      if (!isClosed) {
        emit(state.copyWith(phase: DeviceHostPhase.normal));
      }
    } else {
      _checksDone++;
      if (_checksDone >= _maxChecks) {
        // Timed out – stop waiting, user will still see offline page.
        _timer?.cancel();
        if (!isClosed) {
          emit(state.copyWith(phase: DeviceHostPhase.normal));
        }
      }
    }
  }
}
