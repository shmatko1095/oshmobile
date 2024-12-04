import 'dart:developer';

import 'package:chopper/chopper.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:intl/intl.dart';
import 'package:oshmobile/core/common/cubits/app_user/app_user_cubit.dart';
import 'package:oshmobile/core/network/connection_checker.dart';
import 'package:oshmobile/core/web/auth/auth_service.dart';
import 'package:oshmobile/core/web/chopper_example/core/session_storage.dart';
import 'package:oshmobile/core/web/core/api_authenticator.dart';
import 'package:oshmobile/core/web/core/auth_interceptor.dart';
import 'package:oshmobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:oshmobile/features/auth/data/datasources/osh/osh_remote_data_source.dart';
import 'package:oshmobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:oshmobile/features/auth/domain/repository/auth_repository.dart';
import 'package:oshmobile/features/auth/domain/usecases/current_user.dart';
import 'package:oshmobile/features/auth/domain/usecases/user_signin.dart';
import 'package:oshmobile/features/auth/domain/usecases/user_signup.dart';
import 'package:oshmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:oshmobile/features/blog/data/datasources/blog_local_datasource.dart';
import 'package:oshmobile/features/blog/data/datasources/blog_remote_datasource.dart';
import 'package:oshmobile/features/blog/data/repositories/blog_repository_impl.dart';
import 'package:oshmobile/features/blog/domain/repositories/blog_repository.dart';
import 'package:oshmobile/features/blog/domain/usecases/get_all_blogs.dart';
import 'package:oshmobile/features/blog/domain/usecases/upload_blog.dart';
import 'package:oshmobile/features/blog/presentation/bloc/blog_bloc.dart';
import 'package:path_provider/path_provider.dart';

final locator = GetIt.instance;

Future<void> initDependencies() async {
  _initChopperClient();
  _initAuth();
  _initBlog();

  Hive.init((await getApplicationDocumentsDirectory()).path);
  Box hiveBox = await Hive.openBox("blogs");
  locator.registerLazySingleton<Box>(() => hiveBox);

  locator.registerFactory(() => InternetConnection.createInstance(
      checkInterval: const Duration(seconds: 1)));

  //core
  locator.registerLazySingleton(() => AppUserCubit());
  locator.registerFactory<InternetConnectionChecker>(
      () => InternetConnectionCheckerImpl(internetConnection: locator()));
}

void _initBlog() {
  locator
    ..registerFactory<BlogRemoteDatasource>(
      () => BlogRemoteDatasourceImpl(supabaseClient: locator()),
    )
    ..registerFactory<BlogLocalDataSource>(
      () => BlogLocalDataSourceImpl(box: locator()),
    )
    ..registerFactory<BlogRepository>(
      () => BlogRepositoryImpl(
        blogRemoteDatasource: locator(),
        blogLocalDataSource: locator(),
        connectionChecker: locator(),
      ),
    )
    ..registerFactory<UploadBlog>(
      () => UploadBlog(blogRepository: locator()),
    )
    ..registerFactory<GetAllBlogs>(
      () => GetAllBlogs(blogRepository: locator()),
    )
    ..registerLazySingleton<BlogBloc>(
      () => BlogBloc(
        uploadBlog: locator(),
        getAllBlogs: locator(),
      ),
    );
}

void _initAuth() {
  locator
    //Datasource
    ..registerFactory<IAuthRemoteDataSource>(
      () => OshRemoteDataSourceImpl(webClient: locator<ChopperClient>()),
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
    ..registerFactory<CurrentUser>(
      () => CurrentUser(authRepository: locator()),
    )
    //Bloc
    ..registerLazySingleton<AuthBloc>(
      () => AuthBloc(
        userSignUp: locator(),
        userSignIn: locator(),
        currentUser: locator(),
        appUserCubit: locator(),
      ),
    );
}

void _initChopperClient() {
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

  ;

  locator
    ..registerLazySingleton<SessionStorage>(() {
      final sessionStorage = SessionStorage(storage: FlutterSecureStorage());
      sessionStorage.initialize();
      return sessionStorage;
    })
    ..registerLazySingleton<AuthService>(() => AuthService.create())
    ..registerLazySingleton<ApiAuthenticator>(
      () => ApiAuthenticator(
        sessionRepository: locator<SessionStorage>(),
        appUserCubit: locator<AppUserCubit>(),
        authService: locator<AuthService>(),
      ),
    )
    ..registerLazySingleton<ChopperClient>(
      () {
        final chopperClient = ChopperClient(
          converter: const JsonConverter(),
          authenticator: locator<ApiAuthenticator>(),
          services: [locator<AuthService>()],
          interceptors: [
            AuthInterceptor(sessionRepository: locator<SessionStorage>()),
            const HeadersInterceptor({
              'Accept': 'application/json',
              'Connection': 'keep-alive',
            }),
            HttpLoggingInterceptor(),
            CurlInterceptor(),
          ],
        );
        locator<AuthService>().updateClient(chopperClient);
        return chopperClient;
      },
    );
}
