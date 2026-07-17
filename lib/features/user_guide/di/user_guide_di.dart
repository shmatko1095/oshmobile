import 'package:get_it/get_it.dart';
import 'package:oshmobile/features/user_guide/data/repositories/shared_preferences_user_guide_progress_repository.dart';
import 'package:oshmobile/features/user_guide/domain/repositories/user_guide_progress_repository.dart';
import 'package:oshmobile/features/user_guide/presentation/coordination/user_guide_host_registry.dart';
import 'package:oshmobile/features/user_guide/presentation/cubit/user_guide_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void registerUserGuideFeature(GetIt locator) {
  locator
    ..registerLazySingleton<UserGuideProgressRepository>(
      () => SharedPreferencesUserGuideProgressRepository(
        locator<SharedPreferences>(),
      ),
    )
    ..registerLazySingleton<UserGuideHostRegistry>(
      UserGuideHostRegistry.new,
    )
    ..registerFactory<UserGuideCubit>(
      () => UserGuideCubit(
        repository: locator<UserGuideProgressRepository>(),
      ),
    );
}
