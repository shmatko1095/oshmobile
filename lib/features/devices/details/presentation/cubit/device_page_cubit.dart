import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';

import '../../../details/domain/queries/get_device_full.dart';
import '../models/osh_config.dart';

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

final class DevicePageReady extends DevicePageState {
  final Device device;
  final DeviceConfig config;

  const DevicePageReady({required this.device, required this.config});
}

class DevicePageCubit extends Cubit<DevicePageState> {
  final GetDeviceFull _getDeviceFull;

  DevicePageCubit(this._getDeviceFull) : super(const DevicePageLoading());

  Future<void> load(String deviceId) async {
    // if (isClosed) return;
    emit(const DevicePageLoading());

    try {
      final full = await _getDeviceFull(deviceId);
      // if (isClosed) return;

      final cfg = DeviceConfig.fromJson(
        full.configuration['osh-config'] as Map<String, dynamic>? ?? full.configuration,
      );

      // if (isClosed) return;
      emit(DevicePageReady(device: full.device, config: cfg));
    } catch (e, st) {
      // if (isClosed) return;
      OshCrashReporter.logNonFatal(
        e,
        st,
        reason: 'DevicePageCubit: failed to load config',
        context: {'deviceId': deviceId},
      );
      emit(DevicePageError(e.toString()));
    }
  }
}
