import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';
import 'package:oshmobile/features/device_catalog/domain/contracts/device_catalog_sync.dart';
import 'package:oshmobile/features/device_management/domain/usecases/remove_device.dart';
import 'package:oshmobile/features/device_management/domain/usecases/rename_device.dart';

part 'device_management_state.dart';

class DeviceManagementCubit extends Cubit<DeviceManagementState> {
  final RenameDevice _renameDevice;
  final RemoveDevice _removeDevice;
  final DeviceCatalogSync _deviceCatalogSync;

  DeviceManagementCubit({
    required RenameDevice renameDevice,
    required RemoveDevice removeDevice,
    required DeviceCatalogSync deviceCatalogSync,
  })  : _renameDevice = renameDevice,
        _removeDevice = removeDevice,
        _deviceCatalogSync = deviceCatalogSync,
        super(const DeviceManagementState());

  Future<void> renameDevice({
    required String serial,
    required String alias,
    required String description,
  }) async {
    emit(
      state.copyWith(
        status: DeviceManagementStatus.submitting,
        action: DeviceManagementAction.rename,
        clearError: true,
      ),
    );

    final result = await _renameDevice(
      RenameDeviceParams(
        serial: serial,
        alias: alias,
        description: description,
      ),
    );

    await result.fold<Future<void>>(
      (failure) async {
        unawaited(
          OshCrashReporter.logNonFatal(
            failure,
            null,
            reason: 'DeviceManagementCubit: rename device failed',
            context: {
              'feature': 'device_management',
              'action': 'rename_device',
              'serial': serial,
              'alias_length': alias.length,
              'description_length': description.length,
              'failure_type': failure.type.name,
              'failure_message': failure.message ?? '',
            },
          ),
        );
        emit(
          state.copyWith(
            status: DeviceManagementStatus.failure,
            action: DeviceManagementAction.rename,
            errorMessage: failure.message,
          ),
        );
      },
      (_) async {
        try {
          await _deviceCatalogSync.refresh();
        } catch (error, stackTrace) {
          await OshCrashReporter.logNonFatal(
            error,
            stackTrace,
            reason:
                'DeviceManagementCubit: catalog refresh failed after device rename',
            context: {
              'feature': 'device_management',
              'action': 'rename_device_refresh',
              'serial': serial,
            },
          );
          rethrow;
        }
        emit(
          state.copyWith(
            status: DeviceManagementStatus.success,
            action: DeviceManagementAction.rename,
            clearError: true,
          ),
        );
      },
    );
  }

  Future<void> removeDevice({
    required String deviceId,
    required String serial,
  }) async {
    emit(
      state.copyWith(
        status: DeviceManagementStatus.submitting,
        action: DeviceManagementAction.remove,
        clearError: true,
      ),
    );

    final result = await _removeDevice(
      RemoveDeviceParams(serial: serial),
    );

    await result.fold<Future<void>>(
      (failure) async {
        unawaited(
          OshCrashReporter.logNonFatal(
            failure,
            null,
            reason: 'DeviceManagementCubit: remove device failed',
            context: {
              'feature': 'device_management',
              'action': 'remove_device',
              'device_id': deviceId,
              'serial': serial,
              'failure_type': failure.type.name,
              'failure_message': failure.message ?? '',
            },
          ),
        );
        emit(
          state.copyWith(
            status: DeviceManagementStatus.failure,
            action: DeviceManagementAction.remove,
            errorMessage: failure.message,
          ),
        );
      },
      (_) async {
        _deviceCatalogSync.onDeviceRemoved(deviceId);
        try {
          await _deviceCatalogSync.refresh();
        } catch (error, stackTrace) {
          await OshCrashReporter.logNonFatal(
            error,
            stackTrace,
            reason:
                'DeviceManagementCubit: catalog refresh failed after device removal',
            context: {
              'feature': 'device_management',
              'action': 'remove_device_refresh',
              'device_id': deviceId,
              'serial': serial,
            },
          );
          rethrow;
        }
        emit(
          state.copyWith(
            status: DeviceManagementStatus.success,
            action: DeviceManagementAction.remove,
            clearError: true,
          ),
        );
      },
    );
  }
}
