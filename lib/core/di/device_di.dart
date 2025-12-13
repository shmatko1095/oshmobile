import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:oshmobile/core/common/cubits/mqtt/mqtt_comm_cubit.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/features/devices/details/domain/queries/get_device_full.dart';
import 'package:oshmobile/features/devices/details/domain/repositories/control_repository.dart';
import 'package:oshmobile/features/devices/details/domain/usecases/disable_rt_stream.dart';
import 'package:oshmobile/features/devices/details/domain/usecases/enable_rt_stream.dart';
import 'package:oshmobile/features/devices/details/domain/usecases/subscribe_telemetry.dart';
import 'package:oshmobile/features/devices/details/domain/usecases/unsubscribe_telemetry.dart';
import 'package:oshmobile/features/devices/details/domain/usecases/watch_telemetry.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_actions_cubit.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_host_cubit.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_page_cubit.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_state_cubit.dart';
import 'package:oshmobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:oshmobile/features/schedule/domain/usecases/fetch_schedule_all.dart';
import 'package:oshmobile/features/schedule/domain/usecases/save_schedule_all.dart';
import 'package:oshmobile/features/schedule/domain/usecases/set_schedule_mode.dart';
import 'package:oshmobile/features/schedule/domain/usecases/watch_schedule_stream.dart';
import 'package:oshmobile/features/schedule/presentation/cubit/schedule_cubit.dart';
import 'package:oshmobile/features/settings/domain/usecases/fetch_settings_all.dart';
import 'package:oshmobile/features/settings/domain/usecases/save_settings_all.dart';
import 'package:oshmobile/features/settings/domain/usecases/watch_settings_stream.dart';
import 'package:oshmobile/features/settings/presentation/cubit/device_settings_cubit.dart';

import 'device_context.dart';

/// Device DI scope.
///
/// Exactly one device scope is expected to be active in the UI at any time.
/// When the user selects another device, the old device scope is disposed and
/// a new one is created.
///
/// IMPORTANT: We use a generation token (like SessionDi) to protect against
/// Flutter rebuild races (new DeviceScope may mount before old one is disposed).
class DeviceDi {
  static int _gen = 0;
  static int? _activeGen;

  static bool get isActive => _activeGen != null;

  static bool _isDeviceScopeName(String? name) {
    if (name == null) return false;
    return name == 'device' || name.startsWith('device:');
  }

  /// Enter (or replace) the current device scope.
  ///
  /// Returns a generation token that MUST be used for leaving the scope.
  /// This prevents an old widget instance from popping a newer device scope
  /// during fast device switching.
  static Future<int> enter(Device device) async {
    final myGen = ++_gen;

    // Always replace any existing device scope (best-effort).
    await _leaveInternal();

    final scopeName = 'device:${device.id}';
    GetIt.instance.pushNewScope(
      scopeName: scopeName,
      init: (getIt) => _registerDevice(getIt, device),
    );

    _activeGen = myGen;
    return myGen;
  }

  /// Leave the current device scope.
  ///
  /// If [gen] is not the active one, this call is ignored.
  static Future<void> leave({required int gen}) async {
    if (_activeGen == null) return;
    if (gen != _activeGen) return;

    await _leaveInternal();
  }

  static Future<void> _leaveInternal() async {
    // Pop all device scopes that may still be on top (defensive).
    while (_isDeviceScopeName(GetIt.instance.currentScopeName)) {
      try {
        await GetIt.instance.popScope();
      } catch (_) {
        break;
      }
    }

    _activeGen = null;
  }

  static void _registerDevice(GetIt getIt, Device device) {
    final ctx = DeviceContext.fromDevice(device);

    getIt.registerSingleton<DeviceContext>(ctx);

    // ------------ Device-scoped cubits ------------

    getIt.registerLazySingleton<DeviceHostCubit>(
      () => DeviceHostCubit(
        homeCubit: getIt<HomeCubit>(),
        deviceId: ctx.deviceId,
      ),
      dispose: (c) => unawaited(c.close()),
    );

    // HTTP-based device config/details.
    getIt.registerLazySingleton<DevicePageCubit>(
      () => DevicePageCubit(getIt<GetDeviceFull>()),
      dispose: (c) => unawaited(c.close()),
    );

    // Telemetry/state.
    getIt.registerLazySingleton<DeviceStateCubit>(
      () => DeviceStateCubit(
        deviceSn: ctx.deviceSn,
        subscribe: getIt<SubscribeTelemetry>(),
        unsubscribe: getIt<UnsubscribeTelemetry>(),
        watch: getIt<WatchTelemetry>(),
        enableRt: getIt<EnableRtStream>(),
        disableRt: getIt<DisableRtStream>(),
      ),
      dispose: (c) => unawaited(c.close()),
    );

    // Commands.
    getIt.registerLazySingleton<DeviceActionsCubit>(
      () => DeviceActionsCubit(
        control: getIt<ControlRepository>(),
        deviceSn: ctx.deviceSn,
      ),
      dispose: (c) => unawaited(c.close()),
    );

    // Schedule.
    getIt.registerLazySingleton<DeviceScheduleCubit>(
      () => DeviceScheduleCubit(
        deviceSn: ctx.deviceSn,
        fetchAll: getIt<FetchScheduleAll>(),
        saveAll: getIt<SaveScheduleAll>(),
        setMode: getIt<SetScheduleMode>(),
        watchSchedule: getIt<WatchScheduleStream>(),
        comm: getIt<MqttCommCubit>(),
      ),
      dispose: (c) => unawaited(c.close()),
    );

    // Settings.
    getIt.registerLazySingleton<DeviceSettingsCubit>(
      () => DeviceSettingsCubit(
        deviceSn: ctx.deviceSn,
        fetchAll: getIt<FetchSettingsAll>(),
        saveAll: getIt<SaveSettingsAll>(),
        watchStream: getIt<WatchSettingsStream>(),
        comm: getIt<MqttCommCubit>(),
      ),
      dispose: (c) => unawaited(c.close()),
    );
  }
}
