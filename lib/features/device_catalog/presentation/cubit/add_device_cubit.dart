import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';
import 'package:oshmobile/features/device_catalog/domain/contracts/device_catalog_sync.dart';
import 'package:oshmobile/features/device_catalog/domain/usecases/assign_device.dart';

part 'add_device_state.dart';

class AddDeviceCubit extends Cubit<AddDeviceState> {
  final AssignDevice _assignDevice;
  final DeviceCatalogSync _deviceCatalogSync;

  AddDeviceCubit({
    required AssignDevice assignDevice,
    required DeviceCatalogSync deviceCatalogSync,
  })  : _assignDevice = assignDevice,
        _deviceCatalogSync = deviceCatalogSync,
        super(const AddDeviceState());

  Future<void> assignDevice(String serial, String secureCode) async {
    emit(
      state.copyWith(
        status: AddDeviceStatus.submitting,
        clearError: true,
      ),
    );

    final result = await _assignDevice(
      AssignDeviceParams(
        sn: serial,
        sc: secureCode,
      ),
    );

    await result.fold<Future<void>>(
      (failure) async {
        unawaited(
          OshCrashReporter.logNonFatal(
            failure,
            null,
            reason: 'AddDeviceCubit: assign device failed',
            context: {
              'feature': 'device_catalog',
              'action': 'add_device',
              'serial': serial,
              'failure_type': failure.type.name,
              'failure_message': failure.message ?? '',
            },
          ),
        );
        emit(
          state.copyWith(
            status: AddDeviceStatus.failure,
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
                'AddDeviceCubit: catalog refresh failed after device assign',
            context: {
              'feature': 'device_catalog',
              'action': 'add_device_refresh',
              'serial': serial,
            },
          );
          rethrow;
        }
        emit(
          state.copyWith(
            status: AddDeviceStatus.success,
            clearError: true,
          ),
        );
      },
    );
  }
}
