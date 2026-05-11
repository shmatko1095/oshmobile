import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/analytics/osh_analytics.dart';
import 'package:oshmobile/core/analytics/osh_analytics_events.dart';
import 'package:oshmobile/core/common/cubits/auth/global_auth_cubit.dart';
import 'package:oshmobile/core/common/cubits/mqtt/mqtt_comm_cubit.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/presentation/errors/rest_error_localizer.dart';
import 'package:oshmobile/core/usecase/usecase.dart';
import 'package:oshmobile/features/device_catalog/data/selected_device_storage.dart';
import 'package:oshmobile/features/device_catalog/domain/contracts/device_catalog_sync.dart';
import 'package:oshmobile/features/device_catalog/domain/usecases/get_devices.dart';

part 'device_catalog_state.dart';

class DeviceCatalogCubit extends Cubit<DeviceCatalogState>
    implements DeviceCatalogSync {
  final GlobalAuthCubit globalAuthCubit;
  final GetDevices _getDevices;
  final SelectedDeviceStorage _selectedDeviceStorage;
  final MqttCommCubit _comm;

  String? _currentUserUuid;

  DeviceCatalogCubit({
    required this.globalAuthCubit,
    required GetDevices getDevices,
    required SelectedDeviceStorage selectedDeviceStorage,
    required MqttCommCubit comm,
  })  : _getDevices = getDevices,
        _selectedDeviceStorage = selectedDeviceStorage,
        _comm = comm,
        super(const DeviceCatalogState());

  Device? getById(String id) {
    return state.devices.firstWhereOrNull((device) => device.id == id);
  }

  List<Device> getAll() => List<Device>.from(state.devices);

  void selectDevice(String deviceId) {
    final previousId = state.selectedDeviceId;
    final previousDevice = previousId == null ? null : getById(previousId);
    emit(state.copyWith(selectedDeviceId: deviceId, clearError: true));
    unawaited(_selectedDeviceStorage.saveSelectedDevice(_userUuid, deviceId));
    _comm.dropForDevice(previousDevice?.sn);
  }

  @override
  Future<void> refresh() async {
    final userId = _userUuid;
    final userChanged = _currentUserUuid != null && _currentUserUuid != userId;
    _currentUserUuid = userId;

    final savedSelected = _selectedDeviceStorage.loadSelectedDevice(userId);
    final previousSelected =
        userChanged ? null : state.selectedDeviceId ?? savedSelected;
    final isInitialLoad = state.devices.isEmpty;
    final nextStatus = state.devices.isEmpty
        ? DeviceCatalogStatus.loading
        : DeviceCatalogStatus.refreshing;

    emit(
      state.copyWith(
        status: nextStatus,
        selectedDeviceId: previousSelected,
        clearError: true,
      ),
    );

    final result = await _getDevices(NoParams());

    result.fold(
      (failure) {
        final message = RestErrorLocalizer.resolveFailure(failure);
        unawaited(
          OshAnalytics.logEvent(
            OshAnalyticsEvents.deviceCatalogRefreshFailed,
            parameters: {
              'source': isInitialLoad ? 'initial_load' : 'manual_refresh',
              'failure_type': failure.type.name,
              'failure_code': failure.code ?? '',
            },
          ),
        );
        emit(
          state.copyWith(
            status: DeviceCatalogStatus.failure,
            errorMessage: message,
          ),
        );
      },
      (devices) {
        final selectedId = previousSelected != null &&
                devices.any((device) => device.id == previousSelected)
            ? previousSelected
            : null;

        if (selectedId == null && previousSelected != null) {
          unawaited(_selectedDeviceStorage.clearSelectedDevice(userId));
        }

        emit(
          state.copyWith(
            status: DeviceCatalogStatus.ready,
            devices: devices,
            selectedDeviceId: selectedId,
            clearError: true,
          ),
        );
      },
    );
  }

  @override
  void onDeviceRemoved(String deviceId) {
    final wasSelected = state.selectedDeviceId == deviceId;
    final removedDevice = getById(deviceId);
    final devices = state.devices
        .where((device) => device.id != deviceId)
        .toList(growable: false);

    if (wasSelected) {
      unawaited(_selectedDeviceStorage.clearSelectedDevice(_userUuid));
      _comm.dropForDevice(removedDevice?.sn);
    }

    emit(
      state.copyWith(
        devices: devices,
        selectedDeviceId: wasSelected ? null : state.selectedDeviceId,
        status: DeviceCatalogStatus.ready,
        clearError: true,
      ),
    );
  }

  String get _userUuid => globalAuthCubit.getJwtUserData()!.uuid;
}
