import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:oshmobile/core/common/cubits/mqtt/global_mqtt_cubit.dart';
import 'package:oshmobile/core/common/cubits/mqtt/mqtt_comm_cubit.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/contracts/contract_negotiator.dart';
import 'package:oshmobile/core/contracts/device_runtime_contracts.dart';
import 'package:oshmobile/core/contracts/device_contracts_repository.dart';
import 'package:oshmobile/core/contracts/device_contracts_repository_mqtt.dart';
import 'package:oshmobile/core/contracts/device_contracts_topics.dart';
import 'package:oshmobile/core/network/mqtt/device_mqtt_repo.dart';
import 'package:oshmobile/core/network/mqtt/device_topics_v1.dart';
import 'package:oshmobile/core/network/mqtt/json_rpc_client.dart';
import 'package:oshmobile/core/profile/control_state_resolver.dart';
import 'package:oshmobile/core/profile/profile_bundle_repository.dart';
import 'package:oshmobile/features/device_about/data/device_about_repository_mqtt.dart';
import 'package:oshmobile/features/device_about/domain/repositories/device_about_repository.dart';
import 'package:oshmobile/features/devices/details/data/mqtt_telemetry_repository.dart';
import 'package:oshmobile/features/devices/details/data/telemetry_topics.dart';
import 'package:oshmobile/features/devices/details/domain/queries/get_device_full.dart';
import 'package:oshmobile/features/devices/details/domain/repositories/telemetry_repository.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_host_cubit.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_page_cubit.dart';
import 'package:oshmobile/app/device_session/data/device_facade_impl.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:oshmobile/features/schedule/data/schedule_repository_mqtt.dart';
import 'package:oshmobile/features/schedule/data/schedule_topics.dart';
import 'package:oshmobile/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:oshmobile/features/settings/data/settings_repository_mqtt.dart';
import 'package:oshmobile/features/settings/data/settings_topics.dart';
import 'package:oshmobile/features/settings/data/json_schema_settings_ui_schema_builder.dart';
import 'package:oshmobile/features/settings/domain/repositories/settings_repository.dart';
import 'package:oshmobile/features/settings/domain/ui/settings_ui_schema_builder.dart';
import 'package:oshmobile/features/sensors/data/sensors_repository_mqtt.dart';
import 'package:oshmobile/features/sensors/data/sensors_topics.dart';
import 'package:oshmobile/features/sensors/domain/repositories/sensors_repository.dart';
import 'package:oshmobile/core/di/device_context.dart';

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
    getIt.registerLazySingleton<DeviceRuntimeContracts>(
      () => DeviceRuntimeContracts(),
    );

    getIt.registerLazySingleton<TelemetryTopics>(
      () => TelemetryTopics(
        getIt<DeviceMqttTopicsV1>(),
        getIt<DeviceRuntimeContracts>(),
      ),
    );
    getIt.registerLazySingleton<ScheduleTopics>(
      () => ScheduleTopics(
        getIt<DeviceMqttTopicsV1>(),
        getIt<DeviceRuntimeContracts>(),
      ),
    );
    getIt.registerLazySingleton<SettingsTopics>(
      () => SettingsTopics(
        getIt<DeviceMqttTopicsV1>(),
        getIt<DeviceRuntimeContracts>(),
      ),
    );
    getIt.registerLazySingleton<SensorsTopics>(
      () => SensorsTopics(
        getIt<DeviceMqttTopicsV1>(),
        getIt<DeviceRuntimeContracts>(),
      ),
    );

    // ------------ Device-scoped MQTT repositories & usecases ------------

    // Shared JSON-RPC client (rsp subscription).
    getIt.registerLazySingleton<JsonRpcClient>(
      () => JsonRpcClient(
        mqtt: getIt<DeviceMqttRepo>(),
        rspTopic: getIt<DeviceMqttTopicsV1>().rsp(ctx.deviceSn),
      ),
      dispose: (c) => c.dispose(),
    );

    // Telemetry/state.
    getIt.registerLazySingleton<TelemetryRepository>(
      () => MqttTelemetryRepositoryImpl(
        jrpc: getIt<JsonRpcClient>(),
        topics: getIt<TelemetryTopics>(),
        contracts: getIt<DeviceRuntimeContracts>(),
        deviceSn: ctx.deviceSn,
      ),
      dispose: (r) {
        if (r is MqttTelemetryRepositoryImpl) r.dispose();
      },
    );

    // Schedule.
    getIt.registerLazySingleton<ScheduleRepository>(
      () => ScheduleRepositoryMqtt(
        getIt<JsonRpcClient>(),
        getIt<ScheduleTopics>(),
        ctx.deviceSn,
        contracts: getIt<DeviceRuntimeContracts>(),
      ),
      dispose: (r) {
        if (r is ScheduleRepositoryMqtt) r.dispose();
      },
    );

    // Settings.
    getIt.registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryMqtt(
        getIt<JsonRpcClient>(),
        getIt<SettingsTopics>(),
        ctx.deviceSn,
        contracts: getIt<DeviceRuntimeContracts>(),
      ),
      dispose: (r) {
        if (r is SettingsRepositoryMqtt) r.dispose();
      },
    );

    // Sensors.
    getIt.registerLazySingleton<SensorsRepository>(
      () => SensorsRepositoryMqtt(
        getIt<JsonRpcClient>(),
        getIt<SensorsTopics>(),
        ctx.deviceSn,
        contracts: getIt<DeviceRuntimeContracts>(),
      ),
      dispose: (r) {
        if (r is SensorsRepositoryMqtt) r.dispose();
      },
    );

    // Device about (raw device state).
    getIt.registerLazySingleton<DeviceAboutRepository>(
      () => DeviceAboutRepositoryMqtt(
        jrpc: getIt<JsonRpcClient>(),
        topics: getIt<DeviceMqttTopicsV1>(),
        contracts: getIt<DeviceRuntimeContracts>(),
        deviceSn: ctx.deviceSn,
      ),
      dispose: (r) {
        if (r is DeviceAboutRepositoryMqtt) r.dispose();
      },
    );

    getIt.registerLazySingleton<DeviceContractsRepository>(
      () => DeviceContractsRepositoryMqtt(
        getIt<JsonRpcClient>(),
        getIt<DeviceContractsTopics>(),
        ctx.deviceSn,
      ),
      dispose: (r) {
        if (r is DeviceContractsRepositoryMqtt) r.dispose();
      },
    );

    getIt.registerLazySingleton<GetDeviceFull>(
      () => GetDeviceFull(
        deviceRepository: getIt(),
        contractsRepository: getIt<DeviceContractsRepository>(),
        contractNegotiator: getIt<ContractNegotiator>(),
        profileBundleRepository: getIt<ProfileBundleRepository>(),
        runtimeContracts: getIt<DeviceRuntimeContracts>(),
      ),
    );

    // ------------ Device-scoped cubits (UI shell only) ------------

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

    getIt.registerLazySingleton<SettingsUiSchemaBuilder>(
      () => const ProfileBundleSettingsUiSchemaBuilder(),
    );

    // Device facade for UI orchestration (keeps domain services split).
    getIt.registerLazySingleton<DeviceFacade>(
      () => DeviceFacadeImpl(
        ctx: ctx,
        bootstrapDevice: device,
        pageCubit: getIt<DevicePageCubit>(),
        telemetryRepo: getIt<TelemetryRepository>(),
        scheduleRepo: getIt<ScheduleRepository>(),
        settingsRepo: getIt<SettingsRepository>(),
        aboutRepo: getIt<DeviceAboutRepository>(),
        mqttCubit: getIt<GlobalMqttCubit>(),
        commCubit: getIt<MqttCommCubit>(),
        sensorsRepo: getIt<SensorsRepository>(),
        settingsUiSchemaBuilder: getIt<SettingsUiSchemaBuilder>(),
        controlStateResolver: getIt<ControlStateResolver>(),
      ),
      dispose: (f) => unawaited(f.dispose()),
    );
  }
}
