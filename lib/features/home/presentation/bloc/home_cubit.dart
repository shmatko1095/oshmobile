import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/cubits/auth/global_auth_cubit.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/features/home/domain/usecases/assign_device.dart';
import 'package:oshmobile/features/home/domain/usecases/get_user_devices.dart';
import 'package:oshmobile/features/home/domain/usecases/unassign_device.dart';
import 'package:oshmobile/features/home/domain/usecases/update_device_user_data.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final GlobalAuthCubit globalAuthCubit;
  final GetUserDevices _getUserDevices;
  final UnassignDevice _unassignDevice;
  final AssignDevice _assignDevice;
  final UpdateDeviceUserData _updateDeviceUserData;

  List<Device> userDevices = [];

  HomeCubit({
    required this.globalAuthCubit,
    required GetUserDevices getUserDevices,
    required UnassignDevice unassignDevice,
    required AssignDevice assignDevice,
    required UpdateDeviceUserData updateDeviceUserData,
  })  : _getUserDevices = getUserDevices,
        _unassignDevice = unassignDevice,
        _assignDevice = assignDevice,
        _updateDeviceUserData = updateDeviceUserData,
        super(HomeInitial());

  void selectDevice(String deviceId) => emit(state.copyWith(selectedDeviceId: deviceId));

  Future<void> updateDeviceList() async {
    emit(HomeLoading(selectedDeviceId: state.selectedDeviceId));
    final result = await _getUserDevices(_userUuid);
    result.fold(
      (l) {
        _updateDeviceList([]);
      },
      (r) {
        _updateDeviceList(r);
        emit(HomeReady(selectedDeviceId: state.selectedDeviceId));
      },
    );
  }

  Future<void> unassignDevice(String deviceId) async {
    emit(HomeLoading(selectedDeviceId: state.selectedDeviceId));
    final result = await _unassignDevice(UnassignDeviceParams(
      userId: _userUuid,
      deviceId: deviceId,
    ));
    result.fold(
      (l) => emit(HomeFailed(l.message ?? "", selectedDeviceId: state.selectedDeviceId)),
      (r) => updateDeviceList(),
    );
  }

  Future<void> assignDevice(String sn, String sc) async {
    emit(HomeLoading(selectedDeviceId: state.selectedDeviceId));
    final result = await _assignDevice(AssignDeviceParams(
      uuid: _userUuid,
      sn: sn,
      sc: sc,
    ));
    result.fold(
      (l) => emit(HomeAssignFailed(selectedDeviceId: state.selectedDeviceId)),
      (r) {
        emit(HomeAssignDone(selectedDeviceId: state.selectedDeviceId));
        updateDeviceList();
      },
    );
  }

  Future<void> updateDeviceUserData(
    String deviceId,
    String alias,
    String description,
  ) async {
    emit(HomeLoading(selectedDeviceId: state.selectedDeviceId));
    final result = await _updateDeviceUserData(UpdateDeviceUserDataParams(
      deviceId: deviceId,
      alias: alias,
      description: description,
    ));
    result.fold(
      (l) => emit(HomeUpdateDeviceUserDataFailed(selectedDeviceId: state.selectedDeviceId)),
      (r) {
        emit(HomeUpdateDeviceUserDataDone(selectedDeviceId: state.selectedDeviceId));
        updateDeviceList();
      },
    );
  }

  Device? getDeviceById(String id) {
    return userDevices.firstWhere(
      (element) => element.id == id,
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
