import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/analytics/osh_analytics.dart';
import 'package:oshmobile/core/analytics/osh_analytics_events.dart';
import 'package:oshmobile/core/presentation/errors/rest_error_localizer.dart';
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
        final message = RestErrorLocalizer.resolveFailure(failure);
        unawaited(
          OshAnalytics.logEvent(
            OshAnalyticsEvents.deviceRenameFailed,
            parameters: {
              'reason': 'rename_failed',
              'alias_length': alias.length,
              'description_length': description.length,
              'failure_type': failure.type.name,
              'failure_message': failure.message ?? '',
              'failure_code': failure.code ?? '',
            },
          ),
        );
        emit(
          state.copyWith(
            status: DeviceManagementStatus.failure,
            action: DeviceManagementAction.rename,
            errorMessage: message,
          ),
        );
      },
      (_) async {
        try {
          await _deviceCatalogSync.refresh();
        } catch (_) {
          await OshAnalytics.logEvent(
            OshAnalyticsEvents.deviceCatalogRefreshFailed,
            parameters: {
              'source': 'rename_post_refresh',
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
        final message = RestErrorLocalizer.resolveFailure(failure);
        unawaited(
          OshAnalytics.logEvent(
            OshAnalyticsEvents.deviceUnassignFailed,
            parameters: {
              'reason': 'unassign_failed',
              'failure_type': failure.type.name,
              'failure_code': failure.code ?? '',
            },
          ),
        );
        emit(
          state.copyWith(
            status: DeviceManagementStatus.failure,
            action: DeviceManagementAction.remove,
            errorMessage: message,
          ),
        );
      },
      (_) async {
        _deviceCatalogSync.onDeviceRemoved(deviceId);
        try {
          await _deviceCatalogSync.refresh();
        } catch (_) {
          await OshAnalytics.logEvent(
            OshAnalyticsEvents.deviceCatalogRefreshFailed,
            parameters: {
              'source': 'remove_post_refresh',
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
