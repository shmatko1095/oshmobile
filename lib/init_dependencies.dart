import 'dart:developer';

import 'package:chopper/chopper.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:intl/intl.dart';
import 'package:oshmobile/core/common/cubits/global_auth/global_auth_cubit.dart';
import 'package:oshmobile/core/network/chopper_client/auth/auth_service.dart';
import 'package:oshmobile/core/network/chopper_client/core/api_authenticator.dart';
import 'package:oshmobile/core/network/chopper_client/core/auth_interceptor.dart';
import 'package:oshmobile/core/network/chopper_client/core/session_storage.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api_user/osh_api_user_service.dart';
import 'package:oshmobile/core/network/network_utils/connection_checker.dart';
import 'package:oshmobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:oshmobile/features/auth/data/datasources/osh/osh_remote_data_source.dart';
import 'package:oshmobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:oshmobile/features/auth/domain/repository/auth_repository.dart';
import 'package:oshmobile/features/auth/domain/usecases/user_signin.dart';
import 'package:oshmobile/features/auth/domain/usecases/user_signup.dart';
import 'package:oshmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:path_provider/path_provider.dart';

final locator = GetIt.instance;

Future<void> initDependencies() async {
  await _initCore();
  await _initWebClient();
  _initAuthFeature();
  // _initBlog();
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
      () => OshRemoteDataSourceImpl(
        authClient: locator<AuthService>(),
        oshApiUserService: locator<OshApiUserService>(),
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
    //Bloc
    ..registerLazySingleton<AuthBloc>(
      () => AuthBloc(
        userSignUp: locator(),
        userSignIn: locator(),
        globalAuthCubit: locator<GlobalAuthCubit>(),
      ),
    );
}

Future<void> _initWebClient() async {
  chopperLogger.onRecord.listen((record) {
    log(
      '[${DateFormat('hh:mm:ss:S a').format(record.time)}]: ${record.message}',
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
    ..registerLazySingleton<OshApiUserService>(
      () => OshApiUserService.create(),
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
    services: [
      locator<AuthService>(),
      locator<OshApiUserService>(),
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
  locator<OshApiUserService>().updateClient(chopperClient);

  locator.registerSingleton<ChopperClient>(chopperClient);
}
