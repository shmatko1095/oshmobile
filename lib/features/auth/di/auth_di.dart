import 'package:get_it/get_it.dart';
import 'package:oshmobile/core/common/cubits/auth/global_auth_cubit.dart';
import 'package:oshmobile/core/network/chopper_client/auth/auth_service.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_service.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/users/users_v1_service.dart';
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

void registerAuthFeature(GetIt locator) {
  locator
    ..registerFactory<IAuthRemoteDataSource>(
      () => OshAuthRemoteDataSourceImpl(
        authClient: locator<AuthService>(),
        mobileService: locator<MobileV1Service>(),
        usersService: locator<UsersV1Service>(),
      ),
    )
    ..registerFactory<AuthRepository>(
      () => AuthRepositoryImpl(
        authRemoteDataSource: locator(),
        connectionChecker: locator(),
        kc: locator(),
      ),
    )
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
