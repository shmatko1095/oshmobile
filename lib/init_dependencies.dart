import 'package:get_it/get_it.dart';
import 'package:oshmobile/core/di/core_dependencies.dart';
import 'package:oshmobile/core/utils/app_config.dart';
import 'package:oshmobile/features/account_settings/di/account_settings_di.dart';
import 'package:oshmobile/features/auth/di/auth_di.dart';
import 'package:oshmobile/features/ble_provisioning/di/ble_provisioning_di.dart';
import 'package:oshmobile/features/device_catalog/di/device_catalog_di.dart';
import 'package:oshmobile/features/device_management/di/device_management_di.dart';
import 'package:oshmobile/features/devices/di/devices_di.dart';
import 'package:oshmobile/features/startup/di/startup_di.dart';
import 'package:oshmobile/features/telemetry_history/di/telemetry_history_di.dart';
import 'package:oshmobile/features/user_guide/di/user_guide_di.dart';

final locator = GetIt.instance;

Future<void> initDependencies() async {
  locator.registerSingleton<AppConfig>(const AppConfig.dev());

  await registerCoreDependencies(locator);
  await registerKeycloakWrapper(locator);
  await registerWebClient(locator);
  registerStartupFeature(locator);
  await registerMqttClient(locator);
  registerAuthFeature(locator);
  registerDeviceCatalogFeature(locator);
  registerDeviceManagementFeature(locator);
  registerAccountSettingsFeature(locator);
  registerTelemetryHistoryFeature(locator);
  registerUserGuideFeature(locator);
  registerDevicesFeature(locator);
  registerBleProvisioningFeature(locator);
}
