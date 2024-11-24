import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:oshmobile/core/common/cubits/app_user/app_user_cubit.dart';
import 'package:oshmobile/core/network/connection_checker.dart';
import 'package:oshmobile/core/secrets/app_secrets.dart';
import 'package:oshmobile/features/auth/data/datasources/auth_remote_data_source.dart';
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
import 'package:supabase_flutter/supabase_flutter.dart';

final locator = GetIt.instance;

Future<void> initDependencies() async {
  _initAuth();
  _initBlog();

  final supabase = await Supabase.initialize(
    url: AppSecrets.supabaseUrl,
    anonKey: AppSecrets.supabaseAnonKey,
  );

  Hive.init((await getApplicationDocumentsDirectory()).path);
  Box hiveBox = await Hive.openBox("blogs");
  locator.registerLazySingleton<Box>(() => hiveBox);

  locator.registerFactory(() => InternetConnection());
  locator.registerLazySingleton(() => supabase.client);

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
    ..registerFactory<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(supabaseClient: locator()),
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
