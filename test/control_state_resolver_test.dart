import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/common/entities/device/known_device_models.dart';
import 'package:oshmobile/core/network/mqtt/protocol/v1/sensors_models.dart';
import 'package:oshmobile/core/profile/control_binding_registry.dart';
import 'package:oshmobile/core/profile/control_state_resolver.dart';
import 'package:oshmobile/features/schedule/domain/models/calendar_snapshot.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';
import 'package:oshmobile/features/settings/domain/models/settings_snapshot.dart';
import 'support/thermostat_profile_bundle_fixture.dart';

void main() {
  test('control state resolver derives thermostat controls from source states',
      () {
    final bundle = createThermostatProfileBundle(
      serial: 'TEST-SN',
      modelId: t1aFlWzeModelId,
      negotiatedSchemas: const <String>{
        'settings@1',
        'schedule@1',
        'telemetry@1',
        'sensors@1',
      },
    );

    final registry = ControlBindingRegistry(bundle);
    final resolver = const ControlStateResolver();

    final telemetry = TelemetryState(
      climateSensors: const <ClimateSensorTelemetry>[
        ClimateSensorTelemetry(
          id: 'air-1',
          tempValid: true,
          humidityValid: true,
          temp: 21.5,
          humidity: 43.0,
        ),
      ],
      heaterEnabled: true,
      loadFactor: 27,
    );
    final sensors = SensorsState(
      pairing: const SensorPairing(
        enabled: false,
        transport: 'ble',
        timeoutSec: 0,
        startedTs: 0,
      ),
      items: const <SensorMeta>[
        SensorMeta(
          id: 'air-1',
          name: 'Living room',
          ref: true,
          transport: 'ble',
          removable: true,
          kind: 'air',
          tempCalibration: 0,
        ),
      ],
    );
    final schedule = CalendarSnapshot(
      mode: CalendarMode.daily,
      lists: <CalendarMode, List<SchedulePoint>>{
        CalendarMode.daily: const <SchedulePoint>[
          SchedulePoint(
            time: TimeOfDay(hour: 0, minute: 0),
            daysMask: WeekdayMask.all,
            temp: 23,
          ),
        ],
      },
    );
    final settings = SettingsSnapshot.fromJson(const <String, dynamic>{
      'display': <String, dynamic>{'language': 'en'},
    });

    final state = resolver.resolveAll(
      registry: registry,
      controlIds: const <String>[
        'ambient_temperature',
        'ambient_humidity',
        'telemetry_climate_sensors',
        'heater_enabled',
        'heating_activity_24h',
        'schedule_current_target_temp',
        'schedule_next_target_temp',
        'settings_display_language',
      ],
      telemetry: telemetry,
      sensors: sensors,
      schedule: schedule,
      settings: settings,
    );

    expect(state['ambient_temperature'], 21.5);
    expect(state['ambient_humidity'], 43.0);
    expect(state['heater_enabled'], isTrue);
    expect(state['heating_activity_24h'], 27);
    expect(state['schedule_current_target_temp'], 23.0);
    expect(state['schedule_next_target_temp'], const <String, dynamic>{
      'temp': 23.0,
      'hour': 0,
      'minute': 0,
    });
    expect(state['settings_display_language'], 'en');

    final cards = state['telemetry_climate_sensors'] as List<dynamic>;
    expect(cards, hasLength(1));
    expect((cards.single as Map<String, dynamic>)['name'], 'Living room');
  });
}
