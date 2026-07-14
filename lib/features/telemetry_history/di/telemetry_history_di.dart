import 'package:get_it/get_it.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_service.dart';
import 'package:oshmobile/features/telemetry_history/data/datasources/telemetry_history_remote_data_source.dart';
import 'package:oshmobile/features/telemetry_history/data/datasources/telemetry_history_remote_data_source_impl.dart';
import 'package:oshmobile/features/telemetry_history/data/repositories/telemetry_history_repository_impl.dart';
import 'package:oshmobile/features/telemetry_history/data/shared_preferences_daily_energy_usage_cache.dart';
import 'package:oshmobile/features/telemetry_history/data/shared_preferences_temperature_history_preview_cache.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/daily_energy_usage_cache.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/temperature_history_preview_cache.dart';
import 'package:oshmobile/features/telemetry_history/domain/repositories/telemetry_history_repository.dart';
import 'package:oshmobile/features/telemetry_history/domain/usecases/get_telemetry_aggregate.dart';
import 'package:oshmobile/features/telemetry_history/domain/usecases/get_telemetry_history.dart';
import 'package:oshmobile/features/telemetry_history/domain/usecases/get_telemetry_setpoint_history.dart';
import 'package:shared_preferences/shared_preferences.dart';

void registerTelemetryHistoryFeature(GetIt locator) {
  locator
    ..registerLazySingleton<DailyEnergyUsageCache>(
      () => SharedPreferencesDailyEnergyUsageCache(
        locator<SharedPreferences>(),
      ),
    )
    ..registerLazySingleton<TemperatureHistoryPreviewCache>(
      () => SharedPreferencesTemperatureHistoryPreviewCache(
        locator<SharedPreferences>(),
      ),
    )
    ..registerFactory<TelemetryHistoryRemoteDataSource>(
      () => TelemetryHistoryRemoteDataSourceImpl(
        mobileService: locator<MobileV1Service>(),
      ),
    )
    ..registerFactory<TelemetryHistoryRepository>(
      () => TelemetryHistoryRepositoryImpl(
        remote: locator<TelemetryHistoryRemoteDataSource>(),
      ),
    )
    ..registerFactory<GetTelemetryHistory>(
      () => GetTelemetryHistory(
        repository: locator<TelemetryHistoryRepository>(),
      ),
    )
    ..registerFactory<GetTelemetryAggregate>(
      () => GetTelemetryAggregate(
        repository: locator<TelemetryHistoryRepository>(),
      ),
    )
    ..registerFactory<GetTelemetrySetpointHistory>(
      () => GetTelemetrySetpointHistory(
        repository: locator<TelemetryHistoryRepository>(),
      ),
    );
}
