import 'dart:developer';

import 'package:chopper/chopper.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:oshmobile/core/common/cubits/auth/global_auth_cubit.dart';
import 'package:oshmobile/core/common/cubits/mqtt/global_mqtt_cubit.dart';
import 'package:oshmobile/core/network/chopper_client/auth/auth_service.dart';
import 'package:oshmobile/core/network/chopper_client/core/api_authenticator.dart';
import 'package:oshmobile/core/network/chopper_client/core/auth_interceptor.dart';
import 'package:oshmobile/core/network/chopper_client/core/session_storage.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api_device/osh_api_device_service.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api_user/osh_api_user_service.dart';
import 'package:oshmobile/core/network/mqtt/device_mqtt_repo.dart';
import 'package:oshmobile/core/network/mqtt/device_mqtt_repo_impl.dart';
import 'package:oshmobile/core/network/network_utils/connection_checker.dart';
import 'package:oshmobile/core/secrets/app_secrets.dart';
import 'package:oshmobile/core/utils/app_config.dart';
import 'package:oshmobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:oshmobile/features/auth/data/datasources/auth_remote_data_source_impl.dart';
import 'package:oshmobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:oshmobile/features/auth/domain/repository/auth_repository.dart';
import 'package:oshmobile/features/auth/domain/usecases/reset_password.dart';
import 'package:oshmobile/features/auth/domain/usecases/user_signin.dart';
import 'package:oshmobile/features/auth/domain/usecases/user_signup.dart';
import 'package:oshmobile/features/auth/domain/usecases/verify_email.dart';
import 'package:oshmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:oshmobile/features/devices/details/data/mqtt_control_repository.dart';
import 'package:oshmobile/features/devices/details/data/mqtt_telemetry_repository.dart';
import 'package:oshmobile/features/devices/details/data/telemetry_topics.dart';
import 'package:oshmobile/features/devices/details/domain/queries/get_device_full.dart';
import 'package:oshmobile/features/devices/details/domain/repositories/control_repository.dart';
import 'package:oshmobile/features/devices/details/domain/repositories/telemetry_repository.dart';
import 'package:oshmobile/features/devices/details/domain/usecases/disable_rt_stream.dart';
import 'package:oshmobile/features/devices/details/domain/usecases/enable_rt_stream.dart';
import 'package:oshmobile/features/devices/details/domain/usecases/subscribe_telemetry.dart';
import 'package:oshmobile/features/devices/details/domain/usecases/unsubscribe_telemetry.dart';
import 'package:oshmobile/features/devices/details/domain/usecases/watch_telemetry.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_actions_cubit.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_page_cubit.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_state_cubit.dart';
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
import 'package:oshmobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:oshmobile/features/schedule/data/schedule_repository_mqtt.dart';
import 'package:oshmobile/features/schedule/data/schedule_topics.dart';
import 'package:oshmobile/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:oshmobile/features/schedule/domain/usecases/fetch_schedule_all.dart';
import 'package:oshmobile/features/schedule/domain/usecases/save_schedule_all.dart';
import 'package:oshmobile/features/schedule/domain/usecases/set_schedule_mode.dart';
import 'package:oshmobile/features/schedule/domain/usecases/watch_schedule_stream.dart';
import 'package:oshmobile/features/schedule/presentation/cubit/schedule_cubit.dart';
import 'package:path_provider/path_provider.dart';

final locator = GetIt.instance;

Future<void> initDependencies() async {
  locator.registerSingleton(const AppConfig(tenantId: 'devices-dev'));

  await _initCore();
  await _initWebClient();
  await _initMqttClient();
  _initAuthFeature();
  _initHomeFeature();
  _initDevicesFeature();
}

Future<void> _initCore() async {
  // Box
  Hive.init((await getApplicationDocumentsDirectory()).path);
  Box hiveBox = await Hive.openBox("blogs");
  locator.registerLazySingleton<Box>(() => hiveBox);

  // SessionStorage
  final sessionStorage = SessionStorage(storage: FlutterSecureStorage());
  await sessionStorage.initialize();
  locator.registerSingleton<SessionStorage>(sessionStorage);

  // InternetConnectionChecker
  locator.registerFactory(
    () => InternetConnection.createInstance(checkInterval: const Duration(seconds: 1)),
  );
  locator.registerFactory<InternetConnectionChecker>(
    () => InternetConnectionCheckerImpl(internetConnection: locator()),
  );
}

void _initHomeFeature() {
  locator
    ..registerFactory<UserRemoteDataSource>(() => UserRemoteDataSourceImpl(apiUserService: locator<ApiUserService>()))
    ..registerFactory<UserRepository>(
      () => UserRepositoryImpl(dataSource: locator<UserRemoteDataSource>()),
    )
    ..registerFactory<DeviceRemoteDataSource>(
        () => DeviceRemoteDataSourceImpl(apiDeviceService: locator<ApiDeviceService>()))
    ..registerFactory<DeviceRepository>(
      () => DeviceRepositoryImpl(dataSource: locator<DeviceRemoteDataSource>()),
    )
    ..registerFactory<GetUserDevices>(
      () => GetUserDevices(
        userRepository: locator<UserRepository>(),
        deviceRepository: locator<DeviceRepository>(),
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
    ..registerLazySingleton<HomeCubit>(() => HomeCubit(
          globalAuthCubit: locator<GlobalAuthCubit>(),
          getUserDevices: locator<GetUserDevices>(),
          unassignDevice: locator<UnassignDevice>(),
          assignDevice: locator<AssignDevice>(),
          updateDeviceUserData: locator<UpdateDeviceUserData>(),
        ));
}

void _initAuthFeature() {
  locator
    //Datasource
    ..registerFactory<IAuthRemoteDataSource>(
      () => OshAuthRemoteDataSourceImpl(
        authClient: locator<AuthService>(),
        oshApiUserService: locator<ApiUserService>(),
      ),
    )
    //Repository
    ..registerFactory<AuthRepository>(
      () => AuthRepositoryImpl(
        authRemoteDataSource: locator(),
        connectionChecker: locator(),
      ),
    )
    //Use cases
    ..registerFactory<UserSignUp>(
      () => UserSignUp(authRepository: locator()),
    )
    ..registerFactory<UserSignIn>(
      () => UserSignIn(authRepository: locator()),
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
        userSignUp: locator(),
        userSignIn: locator(),
        verifyEmail: locator(),
        resetPassword: locator(),
        globalAuthCubit: locator<GlobalAuthCubit>(),
      ),
    );
}

void _initDevicesFeature() {
  locator
    // DeviceControl
    ..registerLazySingleton<ControlRepository>(
        () => MqttControlRepositoryImpl(locator<DeviceMqttRepo>(), locator<AppConfig>().tenantId))
    ..registerLazySingleton<EnableRtStream>(() => EnableRtStream(locator<ControlRepository>()))
    ..registerLazySingleton<DisableRtStream>(() => DisableRtStream(locator<ControlRepository>()))
    ..registerFactory<DeviceActionsCubit>(() => DeviceActionsCubit(locator<ControlRepository>()))
    // DeviceTelemetry
    ..registerLazySingleton<TelemetryTopics>(() => TelemetryTopics(locator<AppConfig>().tenantId))
    ..registerLazySingleton<TelemetryRepository>(
        () => MqttTelemetryRepositoryImpl(locator<DeviceMqttRepo>(), locator<TelemetryTopics>()))
    ..registerLazySingleton<SubscribeTelemetry>(() => SubscribeTelemetry(locator<TelemetryRepository>()))
    ..registerLazySingleton<UnsubscribeTelemetry>(() => UnsubscribeTelemetry(locator<TelemetryRepository>()))
    ..registerLazySingleton<WatchTelemetry>(() => WatchTelemetry(locator<TelemetryRepository>()))
    ..registerLazySingleton<GetDeviceFull>(() => GetDeviceFull(locator<DeviceRepository>()))
    ..registerFactory<DevicePageCubit>(() => DevicePageCubit(locator<GetDeviceFull>()))
    ..registerFactory<DeviceStateCubit>(() => DeviceStateCubit(
          subscribe: locator<SubscribeTelemetry>(),
          unsubscribe: locator<UnsubscribeTelemetry>(),
          watch: locator<WatchTelemetry>(),
          enableRt: locator<EnableRtStream>(),
          disableRt: locator<DisableRtStream>(),
        ))
    ..registerLazySingleton<ScheduleTopics>(() => ScheduleTopics(locator<AppConfig>().tenantId))
    ..registerLazySingleton<ScheduleRepository>(
        () => ScheduleRepositoryMqtt(locator<DeviceMqttRepo>(), locator<ScheduleTopics>()))
    // ..registerLazySingleton<ScheduleRepository>(() => ScheduleRepositoryMock.demo())
    ..registerLazySingleton<FetchScheduleAll>(() => FetchScheduleAll(locator<ScheduleRepository>()))
    ..registerLazySingleton<SaveScheduleAll>(() => SaveScheduleAll(locator<ScheduleRepository>()))
    ..registerLazySingleton<SetScheduleMode>(() => SetScheduleMode(locator<ScheduleRepository>()))
    ..registerLazySingleton<WatchScheduleStream>(() => WatchScheduleStream(locator<ScheduleRepository>()))
    ..registerFactory<DeviceScheduleCubit>(() => DeviceScheduleCubit(
          fetchAll: locator<FetchScheduleAll>(),
          saveAll: locator<SaveScheduleAll>(),
          setMode: locator<SetScheduleMode>(),
          watchSchedule: locator<WatchScheduleStream>(),
        ))
    ..registerSingleton<DevicePresenterRegistry>(const DevicePresenterRegistry({
      '8c5ea780-3d0d-4886-9334-2b4e781dd51c': ThermostatBasicPresenter(),
    }));
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
    ..registerLazySingleton<ApiUserService>(
      () => ApiUserService.create(),
    )
    ..registerLazySingleton<ApiDeviceService>(
      () => ApiDeviceService.create(),
    )
    ..registerLazySingleton<GlobalAuthCubit>(
      () => GlobalAuthCubit(
        sessionStorage: locator<SessionStorage>(),
        authService: locator<AuthService>(),
      ),
    )
    ..registerLazySingleton<ApiAuthenticator>(
      () => ApiAuthenticator(
        globalAuthCubit: locator<GlobalAuthCubit>(),
      ),
    );

  final chopperClient = ChopperClient(
    converter: const JsonConverter(),
    authenticator: locator<ApiAuthenticator>(),
    services: [locator<AuthService>(), locator<ApiUserService>(), locator<ApiDeviceService>()],
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
  locator<ApiUserService>().updateClient(chopperClient);
  locator<ApiDeviceService>().updateClient(chopperClient);

  locator.registerSingleton<ChopperClient>(chopperClient);
}

Future<void> _initMqttClient() async {
  final repo = DeviceMqttRepoImpl(
    brokerHost: AppSecrets.oshMqttEndpointUrl,
    port: AppSecrets.oshMqttEndpointPort,
    tenantId: "dev",
  );
  locator
    ..registerSingleton<DeviceMqttRepo>(repo)
    ..registerLazySingleton<GlobalMqttCubit>(
      () => GlobalMqttCubit(
        mqttRepo: locator<DeviceMqttRepo>(),
      ),
    );
}
