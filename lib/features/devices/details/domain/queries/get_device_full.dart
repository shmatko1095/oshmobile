import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/features/home/domain/repositories/device_repository.dart';

/// Temporary mock use-case for loading full device description:
/// - device entity
/// - configuration JSON (capabilities + UI hints + settings schema)
/// - modelId
///
/// Later, when real model/config endpoint appears, this should be
/// replaced with a proper backend call for model/config data.
class GetDeviceFull {
  final DeviceRepository deviceRepository;

  GetDeviceFull(this.deviceRepository);

  Future<({Device device, Map<String, dynamic> configuration, String modelId})> call(
    String deviceId,
  ) async {
    final Either<Failure, Device> res =
        await deviceRepository.get(deviceId: deviceId); // TODO: should be modelRepository

    return await res.fold(
      (f) => Future.error(f.message ?? 'Failed to load device'),
      (d) async {
        // Mock configuration JSON used by DeviceConfig.fromJson.
        //
        // It contains:
        // - capabilities: high-level feature flags for the device
        // - ui_hints.dashboard: ordering/visibility for dashboard tiles
        // - ui_hints.settings: schema describing how to render Settings page
        //
        // NOTE:
        // - Actual settings values come from MQTT shadow (SettingsSnapshot),
        //   this config only describes types, limits and grouping.
        final cfg = <String, dynamic>{
          'capabilities': [
            'sensor.humidity',
            'sensor.temperature',
            'setting.target_temperature',
            'switch.heating',
            'sensor.power',
            'stats.heating_duty_24h',
            'sensor.water_inlet_temp',
            'sensor.water_outlet_temp',

            // Settings-related capabilities (optional, just for semantics).
            'settings.display',
            'settings.update',
          ],
          'ui_hints': {
            // Dashboard layout (already used by DeviceConfig).
            'dashboard.order': [
              'currentHumidity',
              'currentTemp',
              'targetTemp',
              'heatingToggle',
            ],
            'dashboard.hidden': [],

            // New: Settings schema used by DeviceSettingsPage.
            'settings': {
              'groups': [
                {
                  'id': 'display',
                  'title': 'Display',
                  'order': [
                    'display.activeBrightness',
                    'display.idleBrightness',
                    'display.idleTime',
                    'display.dimOnIdle',
                  ],
                },
                {
                  'id': 'update',
                  'title': 'Updates',
                  'order': [
                    'update.autoUpdateEnabled',
                    'update.updateAtMidnight',
                    'update.checkIntervalMin',
                  ],
                },
              ],
              'fields': {
                // DISPLAY GROUP
                'display.activeBrightness': {
                  'group': 'display',
                  'type': 'int', // "int" | "double" | "bool" | "string" | "enum"
                  'widget': 'slider', // "slider" | "switch" | "text" | "select"
                  'min': 0,
                  'max': 100,
                  'step': 1,
                  'unit': '%',
                  'default': 100,
                  'title': 'Active brightness',
                },
                'display.idleBrightness': {
                  'group': 'display',
                  'type': 'int',
                  'widget': 'slider',
                  'min': 0,
                  'max': 100,
                  'step': 1,
                  'unit': '%',
                  'default': 10,
                  'title': 'Idle brightness',
                },
                'display.idleTime': {
                  'group': 'display',
                  'type': 'int',
                  'widget': 'slider',
                  'min': 5,
                  'max': 60,
                  'step': 5,
                  'unit': 's',
                  'default': 30,
                  'title': 'Idle timeout',
                },
                'display.dimOnIdle': {
                  'group': 'display',
                  'type': 'bool',
                  'widget': 'switch',
                  'default': true,
                  'title': 'Dim on idle',
                },

                // UPDATE GROUP
                'update.autoUpdateEnabled': {
                  'group': 'update',
                  'type': 'bool',
                  'widget': 'switch',
                  'default': false,
                  'title': 'Auto updates',
                },
                'update.updateAtMidnight': {
                  'group': 'update',
                  'type': 'bool',
                  'widget': 'switch',
                  'default': false,
                  'title': 'Update at midnight',
                },
                // 'update.checkIntervalMin': {
                //   'group': 'update',
                //   'type': 'int',
                //   'widget': 'slider',
                //   'min': 15,
                //   'max': 720,
                //   'step': 15,
                //   'unit': 'min',
                //   'default': 60,
                //   'title': 'Check interval',
                // },
              },
            },
          },
        };

        return (device: d, configuration: cfg, modelId: d.modelId);
      },
    );
  }
}
