import 'dart:developer';

import 'package:chopper/chopper.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:oshmobile/core/common/cubits/global_auth/global_auth_cubit.dart';
import 'package:oshmobile/core/network/chopper_client/auth/auth_service.dart';
import 'package:oshmobile/core/network/chopper_client/core/api_authenticator.dart';
import 'package:oshmobile/core/network/chopper_client/core/auth_interceptor.dart';
import 'package:oshmobile/core/network/chopper_client/core/session_storage.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api_device/osh_api_user_device_service.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api_user/osh_api_user_auth_service.dart';
import 'package:oshmobile/core/network/network_utils/connection_checker.dart';
import 'package:oshmobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:oshmobile/features/auth/data/datasources/osh/osh_remote_data_source.dart';
import 'package:oshmobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:oshmobile/features/auth/domain/repository/auth_repository.dart';
import 'package:oshmobile/features/auth/domain/usecases/reset_password.dart';
import 'package:oshmobile/features/auth/domain/usecases/user_signin.dart';
import 'package:oshmobile/features/auth/domain/usecases/user_signup.dart';
import 'package:oshmobile/features/auth/domain/usecases/verify_email.dart';
import 'package:oshmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:oshmobile/features/home/data/datasources/remote_data_source.dart';
import 'package:oshmobile/features/home/data/datasources/remote_data_source_impl.dart';
import 'package:oshmobile/features/home/data/repositories/osh_repository_impl.dart';
import 'package:oshmobile/features/home/domain/repositories/osh_repository.dart';
import 'package:oshmobile/features/home/domain/usecases/assign_device.dart';
import 'package:oshmobile/features/home/domain/usecases/get_device_list.dart';
import 'package:oshmobile/features/home/domain/usecases/unassign_device.dart';
import 'package:oshmobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:path_provider/path_provider.dart';

final locator = GetIt.instance;

Future<void> initDependencies() async {
  await _initCore();
  await _initWebClient();
  _initAuthFeature();
  _initHomeFeature();
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
    () => InternetConnection.createInstance(
        checkInterval: const Duration(seconds: 1)),
  );
  locator.registerFactory<InternetConnectionChecker>(
    () => InternetConnectionCheckerImpl(internetConnection: locator()),
  );
}

void _initHomeFeature() {
  locator
    ..registerFactory<OshRemoteDataSource>(() => OshDeviceRemoteDataSourceImpl(
        oshApiUserDeviceService: locator<OshApiUserDeviceService>()))
    ..registerFactory<OshRepository>(
      () => OshRepositoryImpl(
          oshRemoteDataSource: locator<OshRemoteDataSource>()),
    )
    ..registerFactory<GetDeviceList>(
      () => GetDeviceList(
        oshRepository: locator<OshRepository>(),
      ),
    )
    ..registerFactory<UnassignDevice>(
      () => UnassignDevice(
        oshRepository: locator<OshRepository>(),
      ),
    )
    ..registerFactory<AssignDevice>(
      () => AssignDevice(
        oshRepository: locator<OshRepository>(),
      ),
    )
    ..registerLazySingleton<HomeCubit>(() => HomeCubit(
          globalAuthCubit: locator<GlobalAuthCubit>(),
          getDeviceList: locator<GetDeviceList>(),
          unassignDevice: locator<UnassignDevice>(),
          assignDevice: locator<AssignDevice>(),
        ));
}

// void _initBlog() {
//   locator
//     ..registerFactory<BlogRemoteDatasource>(
//       () => BlogRemoteDatasourceImpl(supabaseClient: locator()),
//     )
//     ..registerFactory<BlogLocalDataSource>(
//       () => BlogLocalDataSourceImpl(box: locator()),
//     )
//     ..registerFactory<BlogRepository>(
//       () => BlogRepositoryImpl(
//         blogRemoteDatasource: locator(),
//         blogLocalDataSource: locator(),
//         connectionChecker: locator(),
//       ),
//     )
//     ..registerFactory<UploadBlog>(
//       () => UploadBlog(blogRepository: locator()),
//     )
//     ..registerFactory<GetAllBlogs>(
//       () => GetAllBlogs(blogRepository: locator()),
//     )
//     ..registerLazySingleton<BlogBloc>(
//       () => BlogBloc(
//         uploadBlog: locator(),
//         getAllBlogs: locator(),
//       ),
//     );
// }

void _initAuthFeature() {
  locator
    //Datasource
    ..registerFactory<IAuthRemoteDataSource>(
      () => OshAuthRemoteDataSourceImpl(
        authClient: locator<AuthService>(),
        oshApiUserService: locator<OshApiUserAuthService>(),
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
    ..registerLazySingleton<OshApiUserAuthService>(
      () => OshApiUserAuthService.create(),
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
    )
    ..registerLazySingleton<OshApiUserDeviceService>(
      () => OshApiUserDeviceService.create(),
    );

  final chopperClient = ChopperClient(
    converter: const JsonConverter(),
    authenticator: locator<ApiAuthenticator>(),
    services: [
      locator<AuthService>(),
      locator<OshApiUserAuthService>(),
      locator<OshApiUserDeviceService>()
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
  locator<OshApiUserAuthService>().updateClient(chopperClient);
  locator<OshApiUserDeviceService>().updateClient(chopperClient);

  locator.registerSingleton<ChopperClient>(chopperClient);
}
