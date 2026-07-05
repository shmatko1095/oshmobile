import 'package:oshmobile/app/device_session/data/apis/device_about_api_impl.dart';
import 'package:oshmobile/app/device_session/data/apis/device_schedule_api_impl.dart';
import 'package:oshmobile/app/device_session/data/apis/device_sensors_api_impl.dart';
import 'package:oshmobile/app/device_session/data/apis/device_settings_api_impl.dart';
import 'package:oshmobile/app/device_session/data/apis/device_telemetry_api_impl.dart';
import 'package:oshmobile/core/configuration/models/device_configuration_bundle.dart';
import 'package:oshmobile/core/logging/app_log.dart';

class DeviceDomainApiCoordinator {
  final DeviceTelemetryApiImpl _telemetryApi;
  final DeviceScheduleApiImpl _scheduleApi;
  final DeviceSettingsApiImpl _settingsApi;
  final DeviceSensorsApiImpl _sensorsApi;
  final DeviceAboutApiImpl _aboutApi;

  const DeviceDomainApiCoordinator({
    required DeviceTelemetryApiImpl telemetryApi,
    required DeviceScheduleApiImpl scheduleApi,
    required DeviceSettingsApiImpl settingsApi,
    required DeviceSensorsApiImpl sensorsApi,
    required DeviceAboutApiImpl aboutApi,
  })  : _telemetryApi = telemetryApi,
        _scheduleApi = scheduleApi,
        _settingsApi = settingsApi,
        _sensorsApi = sensorsApi,
        _aboutApi = aboutApi;

  Future<void> startSupportedApis(DeviceConfigurationBundle bundle) async {
    await Future.wait<void>([
      if (bundle.canReadDomain('telemetry'))
        _logAndIgnore(_telemetryApi.start(), operation: 'start telemetry'),
      if (bundle.canReadDomain('schedule'))
        _logAndIgnore(_scheduleApi.start(), operation: 'start schedule'),
      if (bundle.canReadDomain('settings'))
        _logAndIgnore(_settingsApi.start(), operation: 'start settings'),
      if (bundle.canReadDomain('sensors'))
        _logAndIgnore(_sensorsApi.start(), operation: 'start sensors'),
      if (bundle.canReadDomain('device'))
        _logAndIgnore(_aboutApi.start(), operation: 'start about'),
    ]);
  }

  Future<void> refreshSupportedSlices(
    DeviceConfigurationBundle bundle, {
    required bool forceGet,
  }) async {
    await Future.wait<void>([
      if (bundle.canReadDomain('telemetry'))
        _logAndIgnore(
          _telemetryApi.get(force: forceGet).then((_) {}),
          operation: 'refresh telemetry',
        ),
      if (bundle.canReadDomain('schedule'))
        _logAndIgnore(
          _scheduleApi.get(force: forceGet).then((_) {}),
          operation: 'refresh schedule',
        ),
      if (bundle.canReadDomain('settings'))
        _logAndIgnore(
          _settingsApi.get(force: forceGet).then((_) {}),
          operation: 'refresh settings',
        ),
      if (bundle.canReadDomain('sensors'))
        _logAndIgnore(
          _sensorsApi.get(force: forceGet).then((_) {}),
          operation: 'refresh sensors',
        ),
      if (bundle.canReadDomain('device'))
        _logAndIgnore(
          _aboutApi.get(force: forceGet).then((_) {}),
          operation: 'refresh about',
        ),
    ]);
  }

  Future<void> disposeApis() async {
    await Future.wait<void>([
      _logAndIgnore(
        _telemetryApi.dispose(),
        operation: 'dispose telemetry API',
      ),
      _logAndIgnore(
        _scheduleApi.dispose(),
        operation: 'dispose schedule API',
      ),
      _logAndIgnore(
        _settingsApi.dispose(),
        operation: 'dispose settings API',
      ),
      _logAndIgnore(
        _aboutApi.dispose(),
        operation: 'dispose about API',
      ),
      _logAndIgnore(
        _sensorsApi.dispose(),
        operation: 'dispose sensors API',
      ),
    ]);
  }

  Future<void> _logAndIgnore(
    Future<void> future, {
    required String operation,
  }) {
    return future.catchError((Object error, StackTrace stackTrace) {
      AppLog.error(
        'DeviceDomainApiCoordinator: $operation failed',
        error: error,
        stackTrace: stackTrace,
      );
    });
  }
}