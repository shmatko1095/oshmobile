import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/configuration/models/device_configuration_bundle.dart';
import 'package:oshmobile/core/configuration/models/model_configuration.dart';
import 'package:oshmobile/features/devices/details/data/configuration_thermostat_dashboard_schema_builder.dart';
import 'package:oshmobile/features/devices/details/domain/models/thermostat_dashboard_schema.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_metric_catalog.dart';

void main() {
  const builder = ConfigurationThermostatDashboardSchemaBuilder();

  test('includes visible power meter widgets when controls are readable', () {
    final bundle = _bundle(
      widgets: const <Map<String, dynamic>>[
        {
          'id': 'voltageNow',
          'control_ids': ['powerMeterVoltageV', 'powerMeterVoltageValid'],
        },
        {
          'id': 'currentNow',
          'control_ids': ['powerMeterCurrentA', 'powerMeterCurrentValid'],
        },
        {
          'id': 'apparentPowerNow',
          'control_ids': [
            'powerMeterApparentPowerVa',
            'powerMeterApparentPowerValid',
          ],
        },
      ],
      controls: const <Map<String, dynamic>>[
        {'id': 'powerMeterVoltageV', 'path': 'power_meter.voltage_v'},
        {
          'id': 'powerMeterVoltageValid',
          'path': 'power_meter.voltage_valid',
        },
        {'id': 'powerMeterCurrentA', 'path': 'power_meter.current_a'},
        {
          'id': 'powerMeterCurrentValid',
          'path': 'power_meter.current_valid',
        },
        {
          'id': 'powerMeterApparentPowerVa',
          'path': 'power_meter.apparent_power_va',
        },
        {
          'id': 'powerMeterApparentPowerValid',
          'path': 'power_meter.apparent_power_valid',
        },
      ],
      readableDomains: const <String>{'telemetry'},
    );

    final schema = builder.build(bundle: bundle);

    expect(
      schema.visibleWidgetIds,
      containsAllInOrder(
        const <String>['voltageNow', 'currentNow', 'apparentPowerNow'],
      ),
    );
  });

  test('hides power meter widget when telemetry is unreadable', () {
    final bundle = _bundle(
      widgets: const <Map<String, dynamic>>[
        {
          'id': 'currentNow',
          'control_ids': ['powerMeterCurrentA', 'powerMeterCurrentValid'],
        },
      ],
      controls: const <Map<String, dynamic>>[
        {'id': 'powerMeterCurrentA', 'path': 'power_meter.current_a'},
        {
          'id': 'powerMeterCurrentValid',
          'path': 'power_meter.current_valid',
        },
      ],
      readableDomains: const <String>{},
    );

    final schema = builder.build(bundle: bundle);

    expect(
      schema.visibleWidgetIds,
      isNot(contains('currentNow')),
    );
  });

  test('maps control indexes to typed tile binds', () {
    final bundle = _bundle(
      widgets: const <Map<String, dynamic>>[
        {
          'id': 'currentNow',
          'control_ids': ['powerMeterCurrentA', 'powerMeterCurrentValid'],
        },
        {
          'id': 'deltaT',
          'control_ids': ['inlet', 'outlet'],
        },
      ],
      controls: const <Map<String, dynamic>>[
        {'id': 'powerMeterCurrentA', 'path': 'power_meter.current_a'},
        {
          'id': 'powerMeterCurrentValid',
          'path': 'power_meter.current_valid',
        },
        {'id': 'inlet', 'path': 'temps.inlet'},
        {'id': 'outlet', 'path': 'temps.outlet'},
      ],
      readableDomains: const <String>{'telemetry'},
    );

    final schema = builder.build(bundle: bundle);

    final currentTile = schema.tiles
        .whereType<ThermostatValueTileSpec>()
        .firstWhere((tile) => tile.type == ThermostatTileType.currentNow);
    expect(currentTile.valueBind, 'powerMeterCurrentA');
    expect(currentTile.validBind, 'powerMeterCurrentValid');

    final deltaTile = schema.tiles.whereType<ThermostatDeltaTileSpec>().single;
    expect(deltaTile.inletBind, 'inlet');
    expect(deltaTile.outletBind, 'outlet');
  });

  test('mode bar keeps configured mode ids as schema-level ids', () {
    final bundle = _bundle(
      widgets: const <Map<String, dynamic>>[
        {
          'id': 'modeBar',
          'control_ids': ['scheduleMode'],
          'options': {
            'modes': ['daily', ' weekly ', '', 'custom_mode'],
          },
        },
      ],
      controls: const <Map<String, dynamic>>[
        {'id': 'scheduleMode', 'path': 'schedule.mode'},
      ],
      readableDomains: const <String>{'telemetry'},
    );

    final schema = builder.build(bundle: bundle);

    expect(schema.modeBar, isNotNull);
    expect(
      schema.modeBar!.visibleModeIds,
      const <String>['daily', 'weekly', 'custom_mode'],
    );
  });

  test('generates separated history intents for energy and electrical groups',
      () {
    final bundle = _bundle(
      widgets: const <Map<String, dynamic>>[
        {
          'id': 'energyUsed',
          'control_ids': ['powerMeterEnergyKwh'],
        },
        {
          'id': 'powerNow',
          'control_ids': [
            'powerMeterActivePowerW',
            'powerMeterActivePowerValid'
          ],
        },
        {
          'id': 'voltageNow',
          'control_ids': ['powerMeterVoltageV', 'powerMeterVoltageValid'],
        },
      ],
      controls: const <Map<String, dynamic>>[
        {'id': 'powerMeterEnergyKwh', 'path': 'power_meter.energy_kwh'},
        {
          'id': 'powerMeterActivePowerW',
          'path': 'power_meter.active_power_w',
        },
        {
          'id': 'powerMeterActivePowerValid',
          'path': 'power_meter.active_power_valid',
        },
        {'id': 'powerMeterVoltageV', 'path': 'power_meter.voltage_v'},
        {
          'id': 'powerMeterVoltageValid',
          'path': 'power_meter.voltage_valid',
        },
      ],
      readableDomains: const <String>{'telemetry'},
    );

    final schema = builder.build(bundle: bundle);

    final energyTile = schema.tiles
        .whereType<ThermostatValueTileSpec>()
        .firstWhere((tile) => tile.type == ThermostatTileType.energyUsed);
    final energyIntent = energyTile.telemetryHistoryIntent;
    expect(energyIntent, isNotNull);
    expect(energyIntent!.group, TelemetryHistoryIntentGroup.energy);
    expect(
      energyIntent.configuredSeriesKeys,
      const <String>[TelemetryHistoryMetricCatalog.powerMeterEnergyWhDelta],
    );

    final voltageTile = schema.tiles
        .whereType<ThermostatValueTileSpec>()
        .firstWhere((tile) => tile.type == ThermostatTileType.voltageNow);
    final voltageIntent = voltageTile.telemetryHistoryIntent;
    expect(voltageIntent, isNotNull);
    expect(voltageIntent!.group, TelemetryHistoryIntentGroup.electrical);
    expect(
      voltageIntent.configuredSeriesKeys,
      contains(TelemetryHistoryMetricCatalog.powerMeterActivePowerW),
    );
    expect(
      voltageIntent.configuredSeriesKeys,
      contains(TelemetryHistoryMetricCatalog.powerMeterVoltageV),
    );
    expect(
      voltageIntent.configuredSeriesKeys,
      isNot(contains(TelemetryHistoryMetricCatalog.powerMeterEnergyWhDelta)),
    );
  });

  test('skips malformed widgets with missing required control indexes', () {
    final bundle = _bundle(
      widgets: const <Map<String, dynamic>>[
        {
          'id': 'deltaT',
          'control_ids': ['inletOnly'],
        },
        {
          'id': 'heroTemperature',
          'control_ids': ['ambientTemperature'],
        },
      ],
      controls: const <Map<String, dynamic>>[
        {'id': 'inletOnly', 'path': 'temps.inlet'},
        {
          'id': 'ambientTemperature',
          'path': 'climate_sensors.ref.temp',
        },
      ],
      readableDomains: const <String>{'telemetry'},
    );

    final schema = builder.build(bundle: bundle);

    expect(
      schema.tiles.whereType<ThermostatDeltaTileSpec>(),
      isEmpty,
    );
    expect(schema.hero, isNull);
  });
}

DeviceConfigurationBundle _bundle({
  required List<Map<String, dynamic>> widgets,
  required List<Map<String, dynamic>> controls,
  required Set<String> readableDomains,
}) {
  return DeviceConfigurationBundle(
    configurationId: 'configuration-1',
    modelId: 'model-1',
    revision: 1,
    status: 'approved',
    firmwareVersion: '0.60.0',
    runtimeContractsByDomain: const <String, RuntimeContractRecord>{},
    runtimeContractsById: const <String, RuntimeContractRecord>{},
    readableDomains: readableDomains,
    patchableDomains: const <String>{},
    configuration: ModelConfiguration.fromJson(
      <String, dynamic>{
        'schema_version': 1,
        'integrations': {
          'oshmobile': {
            'layout': 'thermostat_basic',
            'domains': {
              'telemetry': {'contract_id': 'telemetry@1'},
            },
            'widgets': widgets,
            'controls': [
              for (final control in controls)
                {
                  'id': control['id'],
                  'title': control['id'],
                  'read': {
                    'kind': 'domain_path',
                    'domain': 'telemetry',
                    'path': control['path'],
                  },
                },
            ],
          },
        },
      },
    ),
  );
}
