import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/cubits/global_auth/global_auth_cubit.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/features/home/domain/usecases/assign_device.dart';
import 'package:oshmobile/features/home/domain/usecases/get_user_devices.dart';
import 'package:oshmobile/features/home/domain/usecases/unassign_device.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final GlobalAuthCubit globalAuthCubit;
  final GetUserDevices _getUserDevices;
  final UnassignDevice _unassignDevice;
  final AssignDevice _assignDevice;

  List<Device> userDevices = [];

  HomeCubit({
    required this.globalAuthCubit,
    required GetUserDevices getUserDevices,
    required UnassignDevice unassignDevice,
    required AssignDevice assignDevice,
  })  : _getUserDevices = getUserDevices,
        _unassignDevice = unassignDevice,
        _assignDevice = assignDevice,
        super(HomeInitial());

  Future<void> updateDeviceList() async {
    emit(const HomeLoading());
    final result = await _getUserDevices(_userUuid);
    result.fold(
      (l) => emit(HomeFailed(l.message ?? "")),
      (r) {
        _updateDeviceList(r);
        emit(const HomeReady());
      },
    );
  }

  Future<void> unassignDevice(String deviceId) async {
    emit(const HomeLoading());
    final result = await _unassignDevice(UnassignDeviceParams(
      userId: _userUuid,
      deviceId: deviceId,
    ));
    result.fold(
      (l) => emit(HomeFailed(l.message ?? "")),
      (r) => updateDeviceList(),
    );
  }

  Future<void> assignDevice(String sn, String sc) async {
    emit(const HomeLoading());
    final result = await _assignDevice(AssignDeviceParams(
      uuid: _userUuid,
      sn: sn,
      sc: sc,
    ));
    result.fold(
      (l) => emit(const HomeAssignFailed()),
      (r) {
        emit(const HomeAssignDone());
        updateDeviceList();
      },
    );
  }

  List<Device> getUserDevices() {
    return List.from(userDevices);
  }

  void _updateDeviceList(List<Device> list) {
    userDevices = list;
  }

  String get _userUuid => globalAuthCubit.getJwtUserData()!.uuid;
}
