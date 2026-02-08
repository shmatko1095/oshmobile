import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:oshmobile/core/common/cubits/mqtt/global_mqtt_cubit.dart';
import 'package:oshmobile/core/common/cubits/mqtt/mqtt_comm_cubit.dart';
import 'package:oshmobile/core/common/services/mqtt_session_controller.dart';
import 'package:oshmobile/core/network/mqtt/app_device_id_provider.dart';
import 'package:oshmobile/core/network/mqtt/device_mqtt_repo.dart';
import 'package:oshmobile/core/network/mqtt/device_mqtt_repo_impl.dart';
import 'package:oshmobile/core/network/mqtt/device_topics_v1.dart';
import 'package:oshmobile/core/utils/app_config.dart';
import 'package:oshmobile/features/device_about/data/device_about_repository_mqtt.dart';
import 'package:oshmobile/features/device_about/domain/repositories/device_about_repository.dart';
import 'package:oshmobile/features/device_about/domain/usecases/watch_device_about_stream.dart';
import 'package:oshmobile/features/devices/details/data/mqtt_control_repository.dart';
import 'package:oshmobile/features/devices/details/data/mqtt_telemetry_repository.dart';
import 'package:oshmobile/features/devices/details/data/telemetry_topics.dart';
import 'package:oshmobile/features/devices/details/domain/repositories/control_repository.dart';
import 'package:oshmobile/features/devices/details/domain/repositories/telemetry_repository.dart';
import 'package:oshmobile/features/devices/details/domain/usecases/disable_rt_stream.dart';
import 'package:oshmobile/features/devices/details/domain/usecases/enable_rt_stream.dart';
import 'package:oshmobile/features/devices/details/domain/usecases/subscribe_telemetry.dart';
import 'package:oshmobile/features/devices/details/domain/usecases/unsubscribe_telemetry.dart';
import 'package:oshmobile/features/devices/details/domain/usecases/watch_telemetry.dart';
import 'package:oshmobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:oshmobile/features/home/utils/selected_device_storage.dart';
import 'package:oshmobile/features/schedule/data/schedule_repository_mqtt.dart';
import 'package:oshmobile/features/schedule/data/schedule_topics.dart';
import 'package:oshmobile/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:oshmobile/features/schedule/domain/usecases/fetch_schedule_all.dart';
import 'package:oshmobile/features/schedule/domain/usecases/save_schedule_all.dart';
import 'package:oshmobile/features/schedule/domain/usecases/set_schedule_mode.dart';
import 'package:oshmobile/features/schedule/domain/usecases/watch_schedule_stream.dart';
import 'package:oshmobile/features/settings/data/settings_repository_mqtt.dart';
import 'package:oshmobile/features/settings/data/settings_topics.dart';
import 'package:oshmobile/features/settings/domain/repositories/settings_repository.dart';
import 'package:oshmobile/features/settings/domain/usecases/fetch_settings_all.dart';
import 'package:oshmobile/features/settings/domain/usecases/save_settings_all.dart';
import 'package:oshmobile/features/settings/domain/usecases/watch_settings_stream.dart';

/// Session DI scope.
///
/// Everything that must be recreated on each login MUST live here.
/// In particular, anything that uses MQTT must be session-scoped to avoid
/// stale subscriptions after relogin.
final locator = GetIt.instance;

class SessionCredentials {
  final String userId;
  final String token;

  const SessionCredentials({
    required this.userId,
    required this.token,
  });
}

class SessionDi {
  static int _gen = 0;
  static int? _activeGen;

  static bool get isActive => _activeGen != null;

  static bool _isDeviceScopeName(String? name) {
    if (name == null) return false;
    return name == 'device' || name.startsWith('device:');
  }

  static bool _isSessionScopeName(String? name) {
    if (name == null) return false;
    return name == 'session' || name.startsWith('session:');
  }

  /// Enter (or replace) the current session scope.
  ///
  /// Returns a generation token that MUST be used for leaving the scope.
  /// This prevents an old widget instance from accidentally popping a newer
  /// session scope during relogin rebuild races.
  static Future<int> enter(SessionCredentials creds) async {
    final myGen = ++_gen;

    // Always replace any existing session (best-effort).
    await _leaveInternal();

    final scopeName = 'session:${creds.userId}';

    locator.pushNewScope(
      scopeName: scopeName,
      init: (getIt) => _registerSession(getIt, creds),
    );

    _activeGen = myGen;
    return myGen;
  }

  /// Leave current session scope.
  ///
  /// If [gen] is not the active one, this call is ignored.
  static Future<void> leave({required int gen}) async {
    if (_activeGen == null) return;
    if (gen != _activeGen) return;

    await _leaveInternal();
  }

  static Future<void> _leaveInternal() async {
    // Pop all device scopes that may still be above the session scope.
    while (_isDeviceScopeName(locator.currentScopeName)) {
      try {
        await locator.popScope();
      } catch (_) {
        break;
      }
    }

    // Pop the session scope.
    if (_isSessionScopeName(locator.currentScopeName)) {
      try {
        await locator.popScope();
      } catch (_) {
        // ignore
      }
    }

    _activeGen = null;
  }

  static void _registerSession(GetIt getIt, SessionCredentials creds) {
    // ---------- Core session singletons ----------

    // DeviceId provider is safe to be global, but keeping it session-local is OK.
    // If it is already registered globally, we don't re-register.
    if (!getIt.isRegistered<AppDeviceIdProvider>()) {
      getIt.registerLazySingleton<AppDeviceIdProvider>(() => AppDeviceIdProvider());
    }

    // MQTT transport is session-scoped: brand new client per login.
    getIt.registerLazySingleton<DeviceMqttRepo>(
      () => DeviceMqttRepoImpl(
        deviceIdProvider: getIt<AppDeviceIdProvider>(),
        brokerHost: getIt<AppConfig>().oshMqttEndpointUrl,
        port: getIt<AppConfig>().oshMqttEndpointPort,
        tenantId: getIt<AppConfig>().devicesTenantId,
      ),
      dispose: (repo) {
        // Best-effort async cleanup.
        unawaited(repo.disposeSession());
      },
    );

    // UI-agnostic comm tracker (session scoped).
    getIt.registerLazySingleton<MqttCommCubit>(
      () => MqttCommCubit(),
      dispose: (c) => unawaited(c.close()),
    );

    // Global MQTT state for UI (session scoped).
    getIt.registerLazySingleton<GlobalMqttCubit>(
      () => GlobalMqttCubit(mqttRepo: getIt<DeviceMqttRepo>()),
      dispose: (c) => unawaited(c.close()),
    );

    // Session controller starts MQTT connect on enter and disconnects on dispose.
    getIt.registerSingleton<MqttSessionController>(
      MqttSessionController(
        creds: creds,
        mqtt: getIt<GlobalMqttCubit>(),
        comm: getIt<MqttCommCubit>(),
      ),
      dispose: (c) => unawaited(c.dispose()),
    );

    // ---------- MQTT-based repos/usecases MUST be session-scoped ----------

    // Device control (commands + RT mode).
    getIt.registerLazySingleton<ControlRepository>(
      () => MqttControlRepositoryImpl(getIt<DeviceMqttRepo>(), getIt<AppConfig>().devicesTenantId),
    );
    getIt.registerLazySingleton<EnableRtStream>(() => EnableRtStream(getIt<ControlRepository>()));
    getIt.registerLazySingleton<DisableRtStream>(() => DisableRtStream(getIt<ControlRepository>()));

    // Telemetry/state.
    getIt.registerLazySingleton<TelemetryRepository>(
      () => MqttTelemetryRepositoryImpl(getIt<DeviceMqttRepo>(), getIt<TelemetryTopics>()),
      dispose: (r) {
        if (r is MqttTelemetryRepositoryImpl) r.dispose();
      },
    );
    getIt.registerLazySingleton<SubscribeTelemetry>(() => SubscribeTelemetry(getIt<TelemetryRepository>()));
    getIt.registerLazySingleton<UnsubscribeTelemetry>(() => UnsubscribeTelemetry(getIt<TelemetryRepository>()));
    getIt.registerLazySingleton<WatchTelemetry>(() => WatchTelemetry(getIt<TelemetryRepository>()));

    // Schedule.
    getIt.registerLazySingleton<ScheduleRepository>(
      () => ScheduleRepositoryMqtt(getIt<DeviceMqttRepo>(), getIt<ScheduleTopics>()),
      dispose: (r) {
        if (r is ScheduleRepositoryMqtt) r.dispose();
      },
    );
    getIt.registerLazySingleton<FetchScheduleAll>(() => FetchScheduleAll(getIt<ScheduleRepository>()));
    getIt.registerLazySingleton<SaveScheduleAll>(() => SaveScheduleAll(getIt<ScheduleRepository>()));
    getIt.registerLazySingleton<SetScheduleMode>(() => SetScheduleMode(getIt<ScheduleRepository>()));
    getIt.registerLazySingleton<WatchScheduleStream>(() => WatchScheduleStream(getIt<ScheduleRepository>()));

    // // Settings (REAL MQTT repo is the default one).
    getIt.registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryMqtt(getIt<DeviceMqttRepo>(), getIt<SettingsTopics>()),
      dispose: (r) {
        if (r is SettingsRepositoryMqtt) r.dispose();
      },
    );

    // Settings (REAL MQTT repo is the default one).
    // getIt.registerLazySingleton<SettingsRepository>(
    //   () => SettingsRepositoryMock(),
    //   dispose: (r) {
    //     if (r is SettingsRepositoryMock) r.dispose();
    //   },
    // );

    getIt.registerLazySingleton<FetchSettingsAll>(() => FetchSettingsAll(getIt<SettingsRepository>()));
    getIt.registerLazySingleton<SaveSettingsAll>(() => SaveSettingsAll(getIt<SettingsRepository>()));
    getIt.registerLazySingleton<WatchSettingsStream>(() => WatchSettingsStream(getIt<SettingsRepository>()));

    // Device about (raw device state).
    getIt.registerLazySingleton<DeviceAboutRepository>(
      () => DeviceAboutRepositoryMqtt(getIt<DeviceMqttRepo>(), getIt<DeviceMqttTopicsV1>()),
      dispose: (r) {
        if (r is DeviceAboutRepositoryMqtt) r.dispose();
      },
    );
    getIt.registerLazySingleton<WatchDeviceAboutStream>(() => WatchDeviceAboutStream(getIt<DeviceAboutRepository>()));

    // ---------- HomeCubit must be session-scoped ----------
    getIt.registerLazySingleton<HomeCubit>(
      () => HomeCubit(
        globalAuthCubit: getIt(),
        getUserDevices: getIt(),
        unassignDevice: getIt(),
        assignDevice: getIt(),
        updateDeviceUserData: getIt(),
        selectedDeviceStorage: getIt<SelectedDeviceStorage>(),
        comm: getIt<MqttCommCubit>(),
      ),
      dispose: (c) => unawaited(c.close()),
    );
  }
}
