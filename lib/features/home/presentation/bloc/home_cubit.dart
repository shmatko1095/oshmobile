import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/cubits/global_auth/global_auth_cubit.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/features/home/domain/usecases/assign_device.dart';
import 'package:oshmobile/features/home/domain/usecases/get_device_list.dart';
import 'package:oshmobile/features/home/domain/usecases/unassign_device.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final GlobalAuthCubit globalAuthCubit;
  final GetDeviceList _getDeviceList;
  final UnassignDevice _unassignDevice;
  final AssignDevice _assignDevice;

  HomeCubit({
    required this.globalAuthCubit,
    required GetDeviceList getDeviceList,
    required UnassignDevice unassignDevice,
    required AssignDevice assignDevice,
  })  : _getDeviceList = getDeviceList,
        _unassignDevice = unassignDevice,
        _assignDevice = assignDevice,
        super(HomeInitial());

  Future<void> updateDeviceList() async {
    emit(const HomeLoading());
    final result = await _getDeviceList(_userUuid);
    result.fold(
      (l) => emit(HomeFailed(l.message ?? "")),
      (r) => emit(HomeReady(userDevices: r)),
    );
  }

  Future<void> unassignDevice(String sn) async {
    emit(const HomeLoading());
    final result = await _unassignDevice(UnassignDeviceParams(
      uuid: _userUuid,
      sn: sn,
    ));
    result.fold(
      (l) => emit(HomeFailed(l.message ?? "")),
      (r) => emit(HomeReady(userDevices: r)),
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
      (l) => emit(HomeFailed(l.message ?? "")),
      (r) => emit(HomeReady(userDevices: r)),
    );
  }

  get _userUuid => globalAuthCubit.getJwtUserData()!.uuid;
}
