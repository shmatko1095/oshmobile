import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/analytics/osh_analytics.dart';
import 'package:oshmobile/core/analytics/osh_analytics_events.dart';
import 'package:oshmobile/core/presentation/errors/rest_error_localizer.dart';
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
        final message = RestErrorLocalizer.resolveFailure(failure);
        unawaited(
          OshAnalytics.logEvent(
            OshAnalyticsEvents.deviceAssignFailed,
            parameters: {
              'reason': 'assign_failed',
              'failure_type': failure.type.name,
              'failure_code': failure.code ?? '',
            },
          ),
        );
        emit(
          state.copyWith(
            status: AddDeviceStatus.failure,
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
              'source': 'assign_post_refresh',
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
