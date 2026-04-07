import 'dart:developer';

import 'package:chopper/chopper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:keycloak_wrapper/keycloak_wrapper.dart';
import 'package:oshmobile/core/common/cubits/app/app_lifecycle_cubit.dart';
import 'package:oshmobile/core/common/cubits/app/app_theme_cubit.dart';
import 'package:oshmobile/core/common/cubits/auth/global_auth_cubit.dart';
import 'package:oshmobile/core/configuration/configuration_bundle_repository.dart';
import 'package:oshmobile/core/configuration/configuration_bundle_repository_impl.dart';
import 'package:oshmobile/core/configuration/control_state_resolver.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';
import 'package:oshmobile/core/network/chopper_client/auth/auth_service.dart';
import 'package:oshmobile/core/network/chopper_client/core/api_authenticator.dart';
import 'package:oshmobile/core/network/chopper_client/core/auth_interceptor.dart';
import 'package:oshmobile/core/network/chopper_client/core/session_storage.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_service.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/users/users_v1_service.dart';
import 'package:oshmobile/core/network/mqtt/app_device_id_provider.dart';
import 'package:oshmobile/core/network/mqtt/device_topics_v1.dart';
import 'package:oshmobile/core/network/network_utils/connection_checker.dart';
import 'package:oshmobile/core/permissions/ble_permission_service.dart';
import 'package:oshmobile/core/secrets/app_secrets.dart';
import 'package:oshmobile/core/theme/shared_prefs_theme_mode_storage.dart';
import 'package:oshmobile/core/theme/theme_mode_storage.dart';
import 'package:oshmobile/core/utils/app_config.dart';
import 'package:oshmobile/features/account_settings/domain/usecases/request_my_account_deletion.dart';
import 'package:oshmobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:oshmobile/features/auth/data/datasources/auth_remote_data_source_impl.dart';
import 'package:oshmobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:oshmobile/features/auth/domain/repository/auth_repository.dart';
import 'package:oshmobile/features/auth/domain/usecases/reset_password.dart';
import 'package:oshmobile/features/auth/domain/usecases/sign_in.dart';
import 'package:oshmobile/features/auth/domain/usecases/sign_in_demo.dart';
import 'package:oshmobile/features/auth/domain/usecases/sign_in_google.dart';
import 'package:oshmobile/features/auth/domain/usecases/sign_up.dart';
import 'package:oshmobile/features/auth/domain/usecases/verify_email.dart';
import 'package:oshmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:oshmobile/features/ble_provisioning/data/ble/ble_client.dart';
import 'package:oshmobile/features/ble_provisioning/data/ble/flutter_reactive_ble.dart';
import 'package:oshmobile/features/ble_provisioning/data/crypto/ble_secure_codec.dart';
import 'package:oshmobile/features/ble_provisioning/data/crypto/ble_secure_codec_dev.dart';
import 'package:oshmobile/features/ble_provisioning/data/repositories/ble_provisioning_repository_impl.dart';
import 'package:oshmobile/features/ble_provisioning/domain/repositories/ble_provisioning_repository.dart';
import 'package:oshmobile/features/ble_provisioning/domain/usecases/connect_ble_device.dart';
import 'package:oshmobile/features/ble_provisioning/domain/usecases/connect_wifi_network.dart';
import 'package:oshmobile/features/ble_provisioning/domain/usecases/disconnect_ble_device.dart';
import 'package:oshmobile/features/ble_provisioning/domain/usecases/observe_device_nearby.dart';
import 'package:oshmobile/features/ble_provisioning/domain/usecases/scan_wifi_networks.dart';
import 'package:oshmobile/features/ble_provisioning/presentation/cubit/ble_provisioning_cubit.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/device_presenter.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/thermostat_presenters.dart';
import 'package:oshmobile/features/home/data/datasources/device_remote_data_source.dart';
import 'package:oshmobile/features/home/data/datasources/device_remote_data_source_impl.dart';
import 'package:oshmobile/features/home/data/datasources/user_remote_data_source.dart';
import 'package:oshmobile/features/home/data/datasources/user_remote_data_source_impl.dart';
import 'package:oshmobile/features/home/data/repositories/device_repository_impl.dart';
import 'package:oshmobile/features/home/data/repositories/user_repository_impl.dart';
import 'package:oshmobile/features/home/domain/repositories/device_repository.dart';
import 'package:oshmobile/features/home/domain/repositories/user_repository.dart';
import 'package:oshmobile/features/home/domain/usecases/assign_device.dart';
import 'package:oshmobile/features/home/domain/usecases/get_user_devices.dart';
import 'package:oshmobile/features/home/domain/usecases/unassign_device.dart';
import 'package:oshmobile/features/home/domain/usecases/update_device_user_data.dart';
import 'package:oshmobile/features/home/utils/selected_device_storage.dart';
import 'package:oshmobile/features/telemetry_history/data/datasources/telemetry_history_remote_data_source.dart';
import 'package:oshmobile/features/telemetry_history/data/datasources/telemetry_history_remote_data_source_impl.dart';
import 'package:oshmobile/features/telemetry_history/data/repositories/telemetry_history_repository_impl.dart';
import 'package:oshmobile/features/telemetry_history/domain/repositories/telemetry_history_repository.dart';
import 'package:oshmobile/features/telemetry_history/domain/usecases/get_telemetry_history.dart';
import 'package:shared_preferences/shared_preferences.dart';

final locator = GetIt.instance;

Future<void> initDependencies() async {
  locator.registerSingleton<AppConfig>(const AppConfig.dev());

  await _initCore();
  await _initKeycloakWrapper();
  await _initWebClient();
  await _initMqttClient();
  _initAuthFeature();
  _initHomeFeature();
  _initAccountSettingsFeature();
  _initDevicesFeature();
  _initTelemetryHistoryFeature();
  _initBleProvisioningFeature();
}

Future<void> _initCore() async {
  // Box
  // Hive.init((await getApplicationDocumentsDirectory()).path);
  // Box hiveBox = await Hive.openBox("blogs");
  // locator.registerLazySingleton<Box>(() => hiveBox);

  // SessionStorage
  final sessionStorage = SessionStorage(storage: FlutterSecureStorage());
  await sessionStorage.initialize();
  locator.registerSingleton<SessionStorage>(sessionStorage);

  final sharedPreferences = await SharedPreferences.getInstance();
  locator.registerSingleton<SharedPreferences>(sharedPreferences);

  // InternetConnectionChecker
  locator.registerFactory(
    () => InternetConnection.createInstance(
        checkInterval: const Duration(seconds: 1)),
  );
  locator.registerFactory<InternetConnectionChecker>(
    () => InternetConnectionCheckerImpl(internetConnection: locator()),
  );

  // App lifecycle (global). Updated by AppLifecycleObserver (UI-only widget).
  locator.registerLazySingleton<AppLifecycleCubit>(() => AppLifecycleCubit());
  locator.registerLazySingleton<ThemeModeStorage>(
    () => SharedPrefsThemeModeStorage(locator<SharedPreferences>()),
  );
  locator.registerLazySingleton<AppThemeCubit>(
    () => AppThemeCubit(storage: locator<ThemeModeStorage>()),
  );
}

Future<void> _initKeycloakWrapper() async {
  final keycloakConfig = KeycloakConfig(
    bundleIdentifier: 'com.oshmobile.oshmobile',
    clientId: AppSecrets.clientId,
    clientSecret: AppSecrets.clientSecret,
    frontendUrl: locator<AppConfig>().frontendUrl,
    realm: locator<AppConfig>().usersRealmId,
    additionalScopes: ['offline_access'],
  );

  final keycloakWrapper = KeycloakWrapper(config: keycloakConfig);

  bool isRetrying = false;

  keycloakWrapper.onError = (message, error, stackTrace) async {
    final errorStr = error.toString();
    debugPrint('Keycloak onError triggered: $message $errorStr');

    if (errorStr.contains('BadPaddingException') ||
        errorStr.contains('BAD_DECRYPT') ||
        errorStr.contains('Cipher functions')) {
      if (isRetrying) {
        debugPrint('❌ Fatal: Keycloak recovery failed even after cleanup.');
        return;
      }

      debugPrint(
          '⚠️ Detected corrupted storage via onError. Starting recovery...');
      isRetrying = true;

      try {
        await const FlutterSecureStorage().deleteAll();
        debugPrint('🧹 Storage cleared. Retrying initialization...');

        await keycloakWrapper.initialize();
        debugPrint('✅ Keycloak recovered successfully inside onError.');
      } catch (e, st) {
        OshCrashReporter.logFatal(e, st,
            reason: "Failed to initialize Keycloak");
        debugPrint('❌ Recovery threw an exception: $e');
      }
    }
  };

  try {
    await keycloakWrapper.initialize();
  } catch (e) {
    debugPrint('Keycloak initialize threw explicitly: $e');
  }

  locator.registerSingleton<KeycloakWrapper>(keycloakWrapper);
}

void _initHomeFeature() {
  locator
    ..registerFactory<UserRemoteDataSource>(() =>
        UserRemoteDataSourceImpl(mobileService: locator<MobileV1Service>()))
    ..registerFactory<UserRepository>(
      () => UserRepositoryImpl(dataSource: locator<UserRemoteDataSource>()),
    )
    ..registerFactory<DeviceRemoteDataSource>(
      () =>
          DeviceRemoteDataSourceImpl(mobileService: locator<MobileV1Service>()),
    )
    ..registerFactory<DeviceRepository>(
      () => DeviceRepositoryImpl(dataSource: locator<DeviceRemoteDataSource>()),
    )
    ..registerFactory<GetUserDevices>(
      () => GetUserDevices(
        userRepository: locator<UserRepository>(),
      ),
    )
    ..registerFactory<UnassignDevice>(
      () => UnassignDevice(
        userRepository: locator<UserRepository>(),
      ),
    )
    ..registerFactory<AssignDevice>(
      () => AssignDevice(
        userRepository: locator<UserRepository>(),
      ),
    )
    ..registerFactory<UpdateDeviceUserData>(
      () => UpdateDeviceUserData(
        deviceRepository: locator<DeviceRepository>(),
      ),
    )
    ..registerFactory<SelectedDeviceStorage>(
      () => SelectedDeviceStorage(locator<SharedPreferences>()),
    );
}

void _initAccountSettingsFeature() {
  locator.registerFactory<RequestMyAccountDeletion>(
    () => RequestMyAccountDeletion(
      mobileService: locator<MobileV1Service>(),
    ),
  );
}

void _initAuthFeature() {
  locator
    //Datasource
    ..registerFactory<IAuthRemoteDataSource>(
      () => OshAuthRemoteDataSourceImpl(
        authClient: locator<AuthService>(),
        mobileService: locator<MobileV1Service>(),
        usersService: locator<UsersV1Service>(),
      ),
    )
    //Repository
    ..registerFactory<AuthRepository>(
      () => AuthRepositoryImpl(
        authRemoteDataSource: locator(),
        connectionChecker: locator(),
        kc: locator(),
      ),
    )
    //Use cases
    ..registerFactory<SignUp>(
      () => SignUp(authRepository: locator()),
    )
    ..registerFactory<SignIn>(
      () => SignIn(authRepository: locator()),
    )
    ..registerFactory<SignInDemo>(
      () => SignInDemo(authRepository: locator()),
    )
    ..registerFactory<SignInWithGoogle>(
      () => SignInWithGoogle(authRepository: locator()),
    )
    ..registerFactory<VerifyEmail>(
      () => VerifyEmail(authRepository: locator()),
    )
    ..registerFactory<ResetPassword>(
      () => ResetPassword(authRepository: locator()),
    )
    //Bloc
    ..registerLazySingleton<AuthBloc>(
      () => AuthBloc(
        signUp: locator(),
        signIn: locator(),
        signInDemo: locator(),
        signInWithGoogle: locator(),
        verifyEmail: locator(),
        resetPassword: locator(),
        globalAuthCubit: locator<GlobalAuthCubit>(),
      ),
    );
}

void _initDevicesFeature() {
  // Only *static* / non-session dependencies live here.
  // MQTT-based repos/usecases must be session-scoped (see SessionDi).

  locator
    ..registerLazySingleton<DeviceMqttTopicsV1>(
        () => DeviceMqttTopicsV1(locator<AppConfig>().devicesTenantId))
    ..registerLazySingleton<ControlStateResolver>(
      () => const ControlStateResolver(),
    )
    ..registerLazySingleton<ConfigurationBundleRepository>(
      () => ConfigurationBundleRepositoryImpl(client: locator<ChopperClient>()),
    )
    // Device presenters registry (pure mapping).
    ..registerSingleton<DevicePresenterRegistry>(const DevicePresenterRegistry({
      'thermostat_basic': ThermostatBasicPresenter(),
    }));
}

void _initTelemetryHistoryFeature() {
  locator
    ..registerFactory<TelemetryHistoryRemoteDataSource>(
      () => TelemetryHistoryRemoteDataSourceImpl(
        mobileService: locator<MobileV1Service>(),
      ),
    )
    ..registerFactory<TelemetryHistoryRepository>(
      () => TelemetryHistoryRepositoryImpl(
        remote: locator<TelemetryHistoryRemoteDataSource>(),
      ),
    )
    ..registerFactory<GetTelemetryHistory>(
      () => GetTelemetryHistory(
        repository: locator<TelemetryHistoryRepository>(),
      ),
    );
}

void _initBleProvisioningFeature() {
  locator
    ..registerLazySingleton<BleSecureCodecFactory>(
      () => (secureCode) => DevBleSecureCodec(secureCode),
    )
    ..registerLazySingleton<BlePermissionService>(() => BlePermissionService())
    ..registerLazySingleton<FlutterReactiveBle>(() => FlutterReactiveBle())
    // data
    ..registerLazySingleton<BleClient>(() => ReactiveBleClientImpl(locator()))
    ..registerLazySingleton<BleProvisioningRepository>(
      () => BleProvisioningRepositoryImpl(
        locator<BleClient>(),
        locator<BleSecureCodecFactory>(),
      ),
    )
// domain
    ..registerLazySingleton(() => ConnectBleDevice(locator()))
    ..registerLazySingleton(() => DisconnectBleDevice(locator()))
    ..registerLazySingleton(() => ScanWifiNetworks(locator()))
    ..registerLazySingleton(() => ConnectWifiNetwork(locator()))
    ..registerLazySingleton(() => ObserveDeviceNearby(locator()))

// presentation
    ..registerFactory(() => BleProvisioningCubit(
          permissions: locator(),
          connectBleDevice: locator(),
          disconnectBleDevice: locator(),
          scanWifiNetworks: locator(),
          connectWifiNetwork: locator(),
          observeDeviceNearby: locator(),
        ));
}

Future<void> _initWebClient() async {
  chopperLogger.onRecord.listen((record) {
    final t = record.time;
    final ts = '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}:'
        '${t.second.toString().padLeft(2, '0')}.'
        '${t.millisecond.toString().padLeft(3, '0')}';

    log(
      '[$ts] ${record.loggerName} ${record.level.name}: ${record.message}',
      zone: record.zone,
      time: record.time,
      error: record.error,
      name: record.loggerName,
      level: record.level.value,
      stackTrace: record.stackTrace,
      sequenceNumber: record.sequenceNumber,
    );
  });

  locator
    ..registerLazySingleton<AuthService>(
      () => AuthService.create(),
    )
    ..registerLazySingleton<UsersV1Service>(
      () => UsersV1Service.create(),
    )
    ..registerLazySingleton<MobileV1Service>(
      () => MobileV1Service.create(),
    )
    ..registerLazySingleton<GlobalAuthCubit>(
      () => GlobalAuthCubit(
          sessionStorage: locator<SessionStorage>(),
          authService: locator<AuthService>(),
          mobileService: locator<MobileV1Service>(),
          keycloakWrapper: locator<KeycloakWrapper>()),
    )
    ..registerLazySingleton<ApiAuthenticator>(
      () => ApiAuthenticator(
        globalAuthCubit: locator<GlobalAuthCubit>(),
      ),
    );

  final chopperClient = ChopperClient(
    converter: const JsonConverter(),
    authenticator: locator<ApiAuthenticator>(),
    services: [
      locator<AuthService>(),
      locator<UsersV1Service>(),
      locator<MobileV1Service>(),
    ],
    interceptors: [
      AuthInterceptor(globalAuthCubit: locator<GlobalAuthCubit>()),
      const HeadersInterceptor({
        'Accept': 'application/json',
        'Connection': 'keep-alive',
      }),
      HttpLoggingInterceptor(),
      CurlInterceptor(),
    ],
  );
  locator<AuthService>().updateClient(chopperClient);
  locator<UsersV1Service>().updateClient(chopperClient);
  locator<MobileV1Service>().updateClient(chopperClient);

  locator.registerSingleton<ChopperClient>(chopperClient);
}

Future<void> _initMqttClient() async {
  locator
      .registerLazySingleton<AppDeviceIdProvider>(() => AppDeviceIdProvider());
}
