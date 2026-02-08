import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/cubits/auth/global_auth_cubit.dart';
import 'package:oshmobile/core/common/cubits/mqtt/mqtt_comm_cubit.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';
import 'package:oshmobile/features/home/domain/usecases/assign_device.dart';
import 'package:oshmobile/features/home/domain/usecases/get_user_devices.dart';
import 'package:oshmobile/features/home/domain/usecases/unassign_device.dart';
import 'package:oshmobile/features/home/domain/usecases/update_device_user_data.dart';
import 'package:oshmobile/features/home/utils/selected_device_storage.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final GlobalAuthCubit globalAuthCubit;
  final GetUserDevices _getUserDevices;
  final UnassignDevice _unassignDevice;
  final AssignDevice _assignDevice;
  final UpdateDeviceUserData _updateDeviceUserData;
  final SelectedDeviceStorage _selectedDeviceStorage;
  final MqttCommCubit _comm;

  List<Device> userDevices = [];
  String? _currentUserUuid;

  HomeCubit({
    required this.globalAuthCubit,
    required GetUserDevices getUserDevices,
    required UnassignDevice unassignDevice,
    required AssignDevice assignDevice,
    required UpdateDeviceUserData updateDeviceUserData,
    required SelectedDeviceStorage selectedDeviceStorage,
    required MqttCommCubit comm,
  })  : _getUserDevices = getUserDevices,
        _unassignDevice = unassignDevice,
        _assignDevice = assignDevice,
        _updateDeviceUserData = updateDeviceUserData,
        _selectedDeviceStorage = selectedDeviceStorage,
        _comm = comm,
        super(HomeInitial());

  void selectDevice(String deviceId) {
    final prevDeviceId = state.selectedDeviceId;
    emit(state.copyWith(selectedDeviceId: deviceId));
    _selectedDeviceStorage.saveSelectedDevice(_userUuid, deviceId);
    _comm.dropForDevice(prevDeviceId);
  }

  Future<void> updateDeviceList() async {
    final userId = _userUuid;

    final bool userChanged = _currentUserUuid != null && _currentUserUuid != userId;
    _currentUserUuid = userId;

    final savedSelected = _selectedDeviceStorage.loadSelectedDevice(userId);

    final bool hasSelectedInState = !userChanged && state is HomeReady && state.selectedDeviceId != null;

    if (hasSelectedInState) {
      emit(HomeRefreshing(selectedDeviceId: state.selectedDeviceId));
    } else {
      emit(HomeLoading(selectedDeviceId: savedSelected));
    }

    final result = await _getUserDevices(userId);

    result.fold(
      (l) {
        OshCrashReporter.log("Failed to updateDeviceList, user: $userId device: $savedSelected");
        emit(HomeFailed(l.message, selectedDeviceId: savedSelected));
      },
      (devices) {
        _updateDeviceList(devices);
        final stillExists = savedSelected != null && devices.any((d) => d.id == savedSelected);
        final selectedId = stillExists ? savedSelected : null;

        if (!stillExists && savedSelected != null) {
          _selectedDeviceStorage.clearSelectedDevice(userId);
        }

        emit(HomeReady(selectedDeviceId: selectedId));
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
      (l) {
        OshCrashReporter.log("Failed to unassignDevice, user: $_userUuid device: $deviceId");
        emit(HomeFailed(l.message ?? "", selectedDeviceId: state.selectedDeviceId));
      },
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
      (l) {
        OshCrashReporter.log("Failed to assignDevice, user: $_userUuid device: $sn");
        emit(HomeAssignFailed(selectedDeviceId: state.selectedDeviceId));
      },
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
      (l) {
        OshCrashReporter.log("Failed to updateDeviceUserData, user: $_userUuid device: $deviceId");
        emit(HomeUpdateDeviceUserDataFailed(selectedDeviceId: state.selectedDeviceId));
      },
      (r) {
        emit(HomeUpdateDeviceUserDataDone(selectedDeviceId: state.selectedDeviceId));
        updateDeviceList();
      },
    );
  }

  Device? getDeviceById(String id) {
    return userDevices.firstWhereOrNull((e) => e.id == id);
  }

  List<Device> getUserDevices() {
    return List.from(userDevices);
  }

  void _updateDeviceList(List<Device> list) {
    userDevices = list;
  }

  String get _userUuid => globalAuthCubit.getJwtUserData()!.uuid;
}
