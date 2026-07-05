import 'package:get_it/get_it.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_service.dart';
import 'package:oshmobile/features/account_settings/domain/usecases/request_my_account_deletion.dart';

void registerAccountSettingsFeature(GetIt locator) {
  locator.registerFactory<RequestMyAccountDeletion>(
    () => RequestMyAccountDeletion(
      mobileService: locator<MobileV1Service>(),
    ),
  );
}