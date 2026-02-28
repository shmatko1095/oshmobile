import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';
import 'package:oshmobile/core/contracts/device_contracts_models.dart';
import 'package:oshmobile/core/profile/models/device_profile_bundle.dart';

import '../../../details/domain/queries/get_device_full.dart';

sealed class DevicePageState {
  const DevicePageState();
}

final class DevicePageLoading extends DevicePageState {
  const DevicePageLoading();
}

final class DevicePageError extends DevicePageState {
  final String message;

  const DevicePageError(this.message);
}

final class DevicePageUpdateRequired extends DevicePageState {
  final String message;

  const DevicePageUpdateRequired(this.message);
}

final class DevicePageCompatibilityError extends DevicePageState {
  final String message;

  const DevicePageCompatibilityError(this.message);
}

final class DevicePageReady extends DevicePageState {
  final Device device;
  final DeviceProfileBundle bundle;
  final NegotiatedContractSet negotiated;

  const DevicePageReady({
    required this.device,
    required this.bundle,
    required this.negotiated,
  });
}

class DevicePageCubit extends Cubit<DevicePageState> {
  final GetDeviceFull _getDeviceFull;

  DevicePageCubit(this._getDeviceFull) : super(const DevicePageLoading());

  Future<void> load(String deviceId) async {
    // if (isClosed) return;
    emit(const DevicePageLoading());

    try {
      final full = await _getDeviceFull(deviceId);
      emit(DevicePageReady(
        device: full.device,
        bundle: full.bundle,
        negotiated: full.negotiated,
      ));
    } on UpdateAppRequired catch (e, st) {
      _reportFailure(
        error: e,
        stackTrace: st,
        deviceId: deviceId,
      );
      emit(DevicePageUpdateRequired(e.message));
    } on CompatibilityError catch (e, st) {
      _reportFailure(
        error: e,
        stackTrace: st,
        deviceId: deviceId,
      );
      emit(DevicePageCompatibilityError(e.message));
    } catch (e, st) {
      _reportFailure(
        error: e,
        stackTrace: st,
        deviceId: deviceId,
      );
      emit(DevicePageError(e.toString()));
    }
  }

  void _reportFailure({
    required Object error,
    required StackTrace stackTrace,
    required String deviceId,
  }) {
    OshCrashReporter.logNonFatal(
      error,
      stackTrace,
      reason: 'DevicePageCubit: failed to load config',
      context: {'deviceId': deviceId},
    );
  }
}
