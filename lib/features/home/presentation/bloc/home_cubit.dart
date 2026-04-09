import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/analytics/osh_analytics.dart';
import 'package:oshmobile/core/analytics/osh_analytics_events.dart';
import 'package:oshmobile/core/common/cubits/auth/global_auth_cubit.dart';
import 'package:oshmobile/core/common/cubits/mqtt/mqtt_comm_cubit.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';
import 'package:oshmobile/core/usecase/usecase.dart';
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
    final device = getDeviceById(deviceId);
    emit(state.copyWith(selectedDeviceId: deviceId));
    _selectedDeviceStorage.saveSelectedDevice(_userUuid, deviceId);
    _comm.dropForDevice(prevDeviceId);
    if (device != null) {
      unawaited(
        OshAnalytics.logEvent(
          OshAnalyticsEvents.deviceSelected,
          parameters: {
            'online': device.connectionInfo.online,
          },
        ),
      );
    }
  }

  Future<void> updateDeviceList() async {
    final userId = _userUuid;

    final bool userChanged =
        _currentUserUuid != null && _currentUserUuid != userId;
    _currentUserUuid = userId;

    final savedSelected = _selectedDeviceStorage.loadSelectedDevice(userId);

    final bool hasSelectedInState =
        !userChanged && state is HomeReady && state.selectedDeviceId != null;

    if (hasSelectedInState) {
      emit(HomeRefreshing(selectedDeviceId: state.selectedDeviceId));
    } else {
      emit(HomeLoading(selectedDeviceId: savedSelected));
    }

    final result = await _getUserDevices(NoParams());

    result.fold(
      (l) {
        OshCrashReporter.log(
            "Failed to updateDeviceList, user: $userId device: $savedSelected");
        emit(HomeFailed(l.message, selectedDeviceId: savedSelected));
      },
      (devices) {
        _updateDeviceList(devices);
        unawaited(
          OshAnalytics.logEvent(
            OshAnalyticsEvents.deviceListLoaded,
            parameters: {'device_count': devices.length},
          ),
        );
        final stillExists =
            savedSelected != null && devices.any((d) => d.id == savedSelected);
        final selectedId = stillExists ? savedSelected : null;

        if (!stillExists && savedSelected != null) {
          _selectedDeviceStorage.clearSelectedDevice(userId);
        }

        emit(HomeReady(selectedDeviceId: selectedId));
      },
    );
  }

  Future<void> unassignDevice(String deviceId) async {
    final device = getDeviceById(deviceId);
    if (device == null) {
      emit(HomeFailed('Device not found',
          selectedDeviceId: state.selectedDeviceId));
      return;
    }

    final prevDevices = List<Device>.from(userDevices);
    final prevSelected = state.selectedDeviceId;

    userDevices =
        userDevices.where((d) => d.id != deviceId).toList(growable: false);
    final nextSelected = prevSelected == deviceId ? null : prevSelected;
    emit(state.copyWith(selectedDeviceId: nextSelected));

    emit(HomeLoading(selectedDeviceId: nextSelected));
    final result = await _unassignDevice(UnassignDeviceParams(
      serial: device.sn,
    ));
    result.fold(
      (l) {
        userDevices = prevDevices;
        OshCrashReporter.log(
            "Failed to unassignDevice, user: $_userUuid device: $deviceId");
        emit(HomeFailed(l.message ?? "", selectedDeviceId: prevSelected));
      },
      (r) {
        if (prevSelected == deviceId) {
          _selectedDeviceStorage.clearSelectedDevice(_userUuid);
          _comm.dropForDevice(deviceId);
        }
        unawaited(OshAnalytics.logEvent(OshAnalyticsEvents.deviceUnassigned));
        updateDeviceList();
      },
    );
  }

  Future<void> assignDevice(String sn, String sc) async {
    await OshAnalytics.logEvent(OshAnalyticsEvents.deviceAssignStarted);
    emit(HomeLoading(selectedDeviceId: state.selectedDeviceId));
    final result = await _assignDevice(AssignDeviceParams(
      sn: sn,
      sc: sc,
    ));
    result.fold(
      (l) {
        OshCrashReporter.log(
            "Failed to assignDevice, user: $_userUuid device: $sn");
        unawaited(
          OshAnalytics.logEvent(
            OshAnalyticsEvents.deviceAssignFailed,
            parameters: {
              'reason': _analyticsReason(l.message),
            },
          ),
        );
        emit(HomeAssignFailed(
          message: l.message,
          selectedDeviceId: state.selectedDeviceId,
        ));
      },
      (r) {
        unawaited(
            OshAnalytics.logEvent(OshAnalyticsEvents.deviceAssignSucceeded));
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
    final device = getDeviceById(deviceId);
    if (device == null) {
      emit(HomeFailed('Device not found',
          selectedDeviceId: state.selectedDeviceId));
      return;
    }

    emit(HomeLoading(selectedDeviceId: state.selectedDeviceId));
    final result = await _updateDeviceUserData(UpdateDeviceUserDataParams(
      serial: device.sn,
      alias: alias,
      description: description,
    ));
    result.fold(
      (l) {
        OshCrashReporter.log(
            "Failed to updateDeviceUserData, user: $_userUuid device: $deviceId");
        emit(HomeUpdateDeviceUserDataFailed(
          message: l.message,
          selectedDeviceId: state.selectedDeviceId,
        ));
      },
      (r) {
        unawaited(OshAnalytics.logEvent(OshAnalyticsEvents.deviceRenameSaved));
        emit(HomeUpdateDeviceUserDataDone(
            selectedDeviceId: state.selectedDeviceId));
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

  String _analyticsReason(String? message) {
    final value = (message ?? '').toLowerCase();
    if (value.contains('timeout')) return 'timeout';
    if (value.contains('conflict')) return 'conflict';
    if (value.contains('invalid')) return 'invalid';
    if (value.contains('permission')) return 'permission_denied';
    if (value.contains('internet') || value.contains('offline')) {
      return 'no_internet';
    }
    if (value.contains('not found')) return 'not_found';
    return 'error';
  }

  String get _userUuid => globalAuthCubit.getJwtUserData()!.uuid;
}
