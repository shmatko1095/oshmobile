import 'package:get_it/get_it.dart';
import 'package:oshmobile/core/common/cubits/auth/global_auth_cubit.dart';
import 'package:oshmobile/core/network/app_client/app_client_metadata_provider.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_service.dart';
import 'package:oshmobile/core/network/network_utils/connection_checker.dart';
import 'package:oshmobile/features/startup/data/repositories/startup_client_policy_repository_impl.dart';
import 'package:oshmobile/features/startup/domain/contracts/startup_auth_bootstrapper.dart';
import 'package:oshmobile/features/startup/domain/repositories/startup_client_policy_repository.dart';
import 'package:oshmobile/features/startup/presentation/cubit/startup_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void registerStartupFeature(GetIt locator) {
  locator
    ..registerLazySingleton<StartupClientPolicyRepository>(
      () => StartupClientPolicyRepositoryImpl(
        mobileService: locator<MobileV1Service>(),
        metadataProvider: locator<AppClientMetadataProvider>(),
        sharedPreferences: locator<SharedPreferences>(),
      ),
    )
    ..registerLazySingleton<StartupAuthBootstrapper>(
      () => locator<GlobalAuthCubit>(),
    )
    ..registerFactory<StartupCubit>(
      () => StartupCubit(
        connectionChecker: locator<InternetConnectionChecker>(),
        authBootstrapper: locator<StartupAuthBootstrapper>(),
        clientPolicyRepository: locator<StartupClientPolicyRepository>(),
      ),
    );
}
