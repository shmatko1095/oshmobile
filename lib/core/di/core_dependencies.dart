import 'package:chopper/chopper.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:keycloak_wrapper/keycloak_wrapper.dart';
import 'package:oshmobile/core/common/cubits/app/app_lifecycle_cubit.dart';
import 'package:oshmobile/core/common/cubits/app/app_theme_cubit.dart';
import 'package:oshmobile/core/common/cubits/auth/global_auth_cubit.dart';
import 'package:oshmobile/core/logging/app_log.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';
import 'package:oshmobile/core/network/app_client/app_client_metadata_provider.dart';
import 'package:oshmobile/core/network/chopper_client/auth/auth_service.dart';
import 'package:oshmobile/core/network/chopper_client/core/api_authenticator.dart';
import 'package:oshmobile/core/network/chopper_client/core/app_client_headers_interceptor.dart';
import 'package:oshmobile/core/network/chopper_client/core/auth_interceptor.dart';
import 'package:oshmobile/core/network/chopper_client/core/session_storage.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_service.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/users/users_v1_service.dart';
import 'package:oshmobile/core/network/mqtt/app_device_id_provider.dart';
import 'package:oshmobile/core/network/network_utils/connection_checker.dart';
import 'package:oshmobile/core/secrets/app_secrets.dart';
import 'package:oshmobile/core/theme/shared_prefs_theme_mode_storage.dart';
import 'package:oshmobile/core/theme/theme_mode_storage.dart';
import 'package:oshmobile/core/utils/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> registerCoreDependencies(GetIt locator) async {
  final sessionStorage = SessionStorage(storage: FlutterSecureStorage());
  await sessionStorage.initialize();
  locator.registerSingleton<SessionStorage>(sessionStorage);

  final sharedPreferences = await SharedPreferences.getInstance();
  locator.registerSingleton<SharedPreferences>(sharedPreferences);

  locator.registerFactory(
    () => InternetConnection.createInstance(
      checkInterval: const Duration(seconds: 1),
    ),
  );
  locator.registerFactory<InternetConnectionChecker>(
    () => InternetConnectionCheckerImpl(internetConnection: locator()),
  );

  locator.registerLazySingleton<AppLifecycleCubit>(() => AppLifecycleCubit());
  locator.registerLazySingleton<ThemeModeStorage>(
    () => SharedPrefsThemeModeStorage(locator<SharedPreferences>()),
  );
  locator.registerLazySingleton<AppThemeCubit>(
    () => AppThemeCubit(storage: locator<ThemeModeStorage>()),
  );
}

Future<void> registerKeycloakWrapper(GetIt locator) async {
  final keycloakConfig = KeycloakConfig(
    bundleIdentifier: 'com.oshmobile.oshmobile',
    clientId: AppSecrets.clientId,
    clientSecret: AppSecrets.clientSecret,
    frontendUrl: locator<AppConfig>().frontendUrl,
    realm: locator<AppConfig>().usersRealmId,
    additionalScopes: ['offline_access'],
  );

  final keycloakWrapper = KeycloakWrapper();
  var isRetrying = false;

  keycloakWrapper.onError = (message, error, stackTrace) async {
    final errorStr = error.toString();
    AppLog.warn('Keycloak onError triggered: $message $errorStr');

    if (errorStr.contains('BadPaddingException') ||
        errorStr.contains('BAD_DECRYPT') ||
        errorStr.contains('Cipher functions')) {
      if (isRetrying) {
        AppLog.error('Keycloak recovery failed even after cleanup.');
        return;
      }

      AppLog.warn('Detected corrupted storage via onError. Starting recovery.');
      isRetrying = true;

      try {
        await const FlutterSecureStorage().deleteAll();
        AppLog.debug('Storage cleared. Retrying initialization.');

        await keycloakWrapper.initialize(config: keycloakConfig);
        AppLog.debug('Keycloak recovered successfully inside onError.');
      } catch (e, st) {
        OshCrashReporter.logFatal(
          e,
          st,
          reason: 'Failed to initialize Keycloak',
        );
        AppLog.error(
          'Keycloak recovery threw an exception',
          error: e,
          stackTrace: st,
        );
      }
    }
  };

  try {
    await keycloakWrapper.initialize(config: keycloakConfig);
  } catch (e) {
    AppLog.error('Keycloak initialize threw explicitly', error: e);
  }

  locator.registerSingleton<KeycloakWrapper>(keycloakWrapper);
}

Future<void> registerWebClient(GetIt locator) async {
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
        keycloakWrapper: locator<KeycloakWrapper>(),
      ),
    )
    ..registerLazySingleton<AppClientMetadataProvider>(
      () => PackageInfoAppClientMetadataProvider(),
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
      AppClientHeadersInterceptor(
        metadataProvider: locator<AppClientMetadataProvider>(),
      ),
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

Future<void> registerMqttClient(GetIt locator) async {
  locator.registerLazySingleton<AppDeviceIdProvider>(
    () => AppDeviceIdProvider(),
  );
}