import 'package:chopper/chopper.dart';
import 'package:get_it/get_it.dart';
import 'package:oshmobile/core/configuration/configuration_bundle_repository.dart';
import 'package:oshmobile/core/configuration/configuration_bundle_repository_impl.dart';
import 'package:oshmobile/core/configuration/control_state_resolver.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_service.dart';
import 'package:oshmobile/core/network/mqtt/device_topics_v1.dart';
import 'package:oshmobile/core/utils/app_config.dart';
import 'package:oshmobile/features/devices/details/data/configuration_thermostat_dashboard_schema_builder.dart';
import 'package:oshmobile/features/devices/details/domain/builders/thermostat_dashboard_schema_builder.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/adapters/thermostat_telemetry_history_opener.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/device_presenter.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/factories/unknown_config_view_model_factory.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/thermostat_presenters.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/unknown_config_presenter.dart';
import 'package:oshmobile/features/home/data/datasources/device_remote_data_source.dart';
import 'package:oshmobile/features/home/data/datasources/device_remote_data_source_impl.dart';
import 'package:oshmobile/features/home/data/repositories/device_repository_impl.dart';
import 'package:oshmobile/features/home/domain/repositories/device_repository.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/daily_energy_usage_cache.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/temperature_history_preview_cache.dart';

void registerDevicesFeature(GetIt locator) {
  // Only static / non-session dependencies live here. MQTT-based repos/usecases
  // must stay session-scoped or device-scoped.
  locator
    ..registerFactory<DeviceRemoteDataSource>(
      () => DeviceRemoteDataSourceImpl(
        mobileService: locator<MobileV1Service>(),
      ),
    )
    ..registerFactory<DeviceRepository>(
      () => DeviceRepositoryImpl(dataSource: locator<DeviceRemoteDataSource>()),
    )
    ..registerLazySingleton<DeviceMqttTopicsV1>(
      () => DeviceMqttTopicsV1(locator<AppConfig>().devicesTenantId),
    )
    ..registerLazySingleton<ControlStateResolver>(
      () => const ControlStateResolver(),
    )
    ..registerLazySingleton<ConfigurationBundleRepository>(
      () => ConfigurationBundleRepositoryImpl(client: locator<ChopperClient>()),
    )
    ..registerLazySingleton<ThermostatDashboardSchemaBuilder>(
      () => const ConfigurationThermostatDashboardSchemaBuilder(),
    )
    ..registerLazySingleton<ThermostatTelemetryHistoryOpener>(
      () => const ThermostatTelemetryHistoryOpener(),
    )
    ..registerLazySingleton<UnknownConfigViewModelFactory>(
      () => const UnknownConfigViewModelFactory(),
    )
    ..registerLazySingleton<ThermostatBasicPresenter>(
      () => ThermostatBasicPresenter(
        schemaBuilder: locator<ThermostatDashboardSchemaBuilder>(),
        historyOpener: locator<ThermostatTelemetryHistoryOpener>(),
        historyPreviewCache: locator<TemperatureHistoryPreviewCache>(),
        dailyEnergyCache: locator<DailyEnergyUsageCache>(),
      ),
    )
    ..registerLazySingleton<UnknownConfigPresenter>(
      () => UnknownConfigPresenter(
        viewModelFactory: locator<UnknownConfigViewModelFactory>(),
      ),
    )
    ..registerSingleton<DevicePresenterRegistry>(
      DevicePresenterRegistry({
        'thermostat_basic': locator<ThermostatBasicPresenter>(),
      }),
    );
}
