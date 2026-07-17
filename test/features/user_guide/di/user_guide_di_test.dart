import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:oshmobile/features/user_guide/di/user_guide_di.dart';
import 'package:oshmobile/features/user_guide/presentation/coordination/user_guide_host_registry.dart';
import 'package:oshmobile/features/user_guide/presentation/cubit/user_guide_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('cubit is factory-owned while host registry is shared', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final locator = GetIt.asNewInstance();
    locator.registerSingleton<SharedPreferences>(preferences);
    registerUserGuideFeature(locator);

    final firstCubit = locator<UserGuideCubit>();
    final secondCubit = locator<UserGuideCubit>();

    expect(identical(firstCubit, secondCubit), isFalse);
    expect(
      identical(
        locator<UserGuideHostRegistry>(),
        locator<UserGuideHostRegistry>(),
      ),
      isTrue,
    );

    await firstCubit.close();
    await secondCubit.close();
    await locator.reset();
  });
}
