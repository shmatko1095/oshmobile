import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/configuration/models/device_configuration_bundle.dart';
import 'package:oshmobile/core/configuration/models/model_configuration.dart';
import 'package:oshmobile/features/devices/details/data/configuration_thermostat_dashboard_schema_builder.dart';
import 'package:oshmobile/features/devices/details/domain/models/thermostat_dashboard_schema.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_metric_catalog.dart';

void main() {
  const builder = ConfigurationThermostatDashboardSchemaBuilder();

  test('builds configured daily 24h stats from two readable controls', () {
    final bundle = _bundle(
      widgets: const <Map<String, dynamic>>[
        {
          'id': 'dailyStats24h',
          'control_ids': [
            'powerMeterEnergyWhDelta',
            'heatingActivity24h',
          ],
        },
      ],
      controls: const <Map<String, dynamic>>[
        {
          'id': 'powerMeterEnergyWhDelta',
          'path': 'power_meter.energy_wh_delta',
        },
        {'id': 'heatingActivity24h', 'path': 'load_factor'},
      ],
      readableDomains: const <String>{'telemetry'},
    );

    final schema = builder.build(bundle: bundle);

    expect(schema.visibleWidgetIds, const <String>['dailyStats24h']);
    expect(
      schema.dailyStats24h?.energySeriesKey,
      TelemetryHistoryMetricCatalog.powerMeterEnergyWhDelta,
    );
    expect(
      schema.dailyStats24h?.heatingActivityBind,
      'heatingActivity24h',
    );
    expect(schema.tiles, isEmpty);
  });

  test('skips daily 24h stats when one required control is unknown', () {
    final bundle = _bundle(
      widgets: const <Map<String, dynamic>>[
        {
          'id': 'dailyStats24h',
          'control_ids': [
            'powerMeterEnergyWhDelta',
            'missingHeatingActivity',
          ],
        },
      ],
      controls: const <Map<String, dynamic>>[
        {
          'id': 'powerMeterEnergyWhDelta',
          'path': 'power_meter.energy_wh_delta',
        },
      ],
      readableDomains: const <String>{'telemetry'},
    );

    final schema = builder.build(bundle: bundle);

    expect(schema.dailyStats24h, isNull);
    expect(schema.visibleWidgetIds, isEmpty);
  });

  test('ignores an unknown widget id without failing the dashboard', () {
    final bundle = _bundle(
      widgets: const <Map<String, dynamic>>[
        {
          'id': 'futureWidget',
          'control_ids': ['knownControl'],
        },
        {
          'id': 'currentNow',
          'control_ids': ['powerMeterCurrentA', 'powerMeterCurrentValid'],
        },
      ],
      controls: const <Map<String, dynamic>>[
        {'id': 'knownControl', 'path': 'known_value'},
        {'id': 'powerMeterCurrentA', 'path': 'power_meter.current_a'},
        {
          'id': 'powerMeterCurrentValid',
          'path': 'power_meter.current_valid',
        },
      ],
      readableDomains: const <String>{'telemetry'},
    );

    final schema = builder.build(bundle: bundle);

    expect(schema.dailyStats24h, isNull);
    expect(schema.visibleWidgetIds, const <String>['currentNow']);
    expect(schema.tiles.single.type, ThermostatTileType.currentNow);
  });

  test('keeps legacy energy and load factor widgets supported', () {
    final bundle = _bundle(
      widgets: const <Map<String, dynamic>>[
        {
          'id': 'loadFactor24h',
          'control_ids': ['heatingActivity24h'],
        },
        {
          'id': 'energyUsed',
          'control_ids': <String>[],
        },
      ],
      controls: const <Map<String, dynamic>>[
        {'id': 'heatingActivity24h', 'path': 'load_factor'},
      ],
      readableDomains: const <String>{'telemetry'},
    );

    final schema = builder.build(bundle: bundle);

    expect(schema.dailyStats24h, isNull);
    expect(
      schema.tiles.map((tile) => tile.type),
      const <ThermostatTileType>[
        ThermostatTileType.loadFactor24h,
        ThermostatTileType.energyUsed,
      ],
    );
  });

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

  test('preserves configured order for live dashboard tiles', () {
    final bundle = _bundle(
      widgets: const <Map<String, dynamic>>[
        {
          'id': 'heatingToggle',
          'control_ids': ['heaterEnabled'],
        },
        {
          'id': 'voltageNow',
          'control_ids': ['powerMeterVoltageV', 'powerMeterVoltageValid'],
        },
        {
          'id': 'currentNow',
          'control_ids': ['powerMeterCurrentA', 'powerMeterCurrentValid'],
        },
        {
          'id': 'powerNow',
          'control_ids': [
            'powerMeterActivePowerW',
            'powerMeterActivePowerValid',
          ],
        },
      ],
      controls: const <Map<String, dynamic>>[
        {'id': 'heaterEnabled', 'path': 'heater_enabled'},
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
          'id': 'powerMeterActivePowerW',
          'path': 'power_meter.active_power_w',
        },
        {
          'id': 'powerMeterActivePowerValid',
          'path': 'power_meter.active_power_valid',
        },
      ],
      readableDomains: const <String>{'telemetry'},
    );

    final schema = builder.build(bundle: bundle);

    expect(
      schema.tiles.map((tile) => tile.type),
      const <ThermostatTileType>[
        ThermostatTileType.heatingToggle,
        ThermostatTileType.voltageNow,
        ThermostatTileType.currentNow,
        ThermostatTileType.powerNow,
      ],
    );
    expect(schema.heatingStatus?.bind, 'heaterEnabled');
    expect(
      schema.tiles.whereType<ThermostatSingleBindTileSpec>().first.bind,
      'heaterEnabled',
    );
  });

  test('does not promote missing or unreadable heating status', () {
    final missingControl = _bundle(
      widgets: const <Map<String, dynamic>>[
        {
          'id': 'heatingToggle',
          'control_ids': ['missingHeaterEnabled'],
        },
      ],
      controls: const <Map<String, dynamic>>[],
      readableDomains: const <String>{'telemetry'},
    );
    final unreadableControl = _bundle(
      widgets: const <Map<String, dynamic>>[
        {
          'id': 'heatingToggle',
          'control_ids': ['heaterEnabled'],
        },
      ],
      controls: const <Map<String, dynamic>>[
        {'id': 'heaterEnabled', 'path': 'heater_enabled'},
      ],
      readableDomains: const <String>{},
    );

    final missingSchema = builder.build(bundle: missingControl);
    final unreadableSchema = builder.build(bundle: unreadableControl);

    expect(missingSchema.heatingStatus, isNull);
    expect(missingSchema.tiles, isEmpty);
    expect(unreadableSchema.heatingStatus, isNull);
    expect(unreadableSchema.tiles, isEmpty);
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

  test('power meter tiles open only their own history metric', () {
    final bundle = _bundle(
      widgets: const <Map<String, dynamic>>[
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

    expect(
      schema.visibleWidgetIds,
      isNot(contains('energyUsed')),
    );

    final powerTile = schema.tiles
        .whereType<ThermostatValueTileSpec>()
        .firstWhere((tile) => tile.type == ThermostatTileType.powerNow);
    final powerIntent = powerTile.telemetryHistoryIntent;
    expect(powerIntent, isNotNull);
    expect(
      powerIntent!.group,
      TelemetryHistoryIntentGroup.single,
    );
    expect(
      powerIntent.initialSeriesKey,
      TelemetryHistoryMetricCatalog.powerMeterActivePowerW,
    );
    expect(
      powerIntent.configuredSeriesKeys,
      const <String>[
        TelemetryHistoryMetricCatalog.powerMeterActivePowerW,
      ],
    );

    final voltageTile = schema.tiles
        .whereType<ThermostatValueTileSpec>()
        .firstWhere((tile) => tile.type == ThermostatTileType.voltageNow);
    final voltageIntent = voltageTile.telemetryHistoryIntent;
    expect(voltageIntent, isNotNull);
    expect(voltageIntent!.group, TelemetryHistoryIntentGroup.single);
    expect(
      voltageIntent.configuredSeriesKeys,
      const <String>[
        TelemetryHistoryMetricCatalog.powerMeterVoltageV,
      ],
    );
  });

  test('keeps energy tile history intent for backward compatible configs', () {
    final bundle = _bundle(
      widgets: const <Map<String, dynamic>>[
        {
          'id': 'energyUsed',
          'control_ids': ['powerMeterEnergyKwh'],
        },
      ],
      controls: const <Map<String, dynamic>>[
        {'id': 'powerMeterEnergyKwh', 'path': 'power_meter.energy_kwh'},
      ],
      readableDomains: const <String>{'telemetry'},
    );

    final schema = builder.build(bundle: bundle);

    final energyTile =
        schema.tiles.whereType<ThermostatDailyEnergyTileSpec>().single;
    final energyIntent = energyTile.telemetryHistoryIntent;
    expect(energyIntent, isNotNull);
    expect(energyIntent!.group, TelemetryHistoryIntentGroup.energy);
    expect(
      energyIntent.configuredSeriesKeys,
      const <String>[TelemetryHistoryMetricCatalog.powerMeterEnergyWhDelta],
    );
  });

  test(
      'renders energy tile without live control ids when telemetry is readable',
      () {
    final bundle = _bundle(
      widgets: const <Map<String, dynamic>>[
        {
          'id': 'energyUsed',
          'control_ids': <String>[],
        },
      ],
      controls: const <Map<String, dynamic>>[],
      readableDomains: const <String>{'telemetry'},
    );

    final schema = builder.build(bundle: bundle);

    expect(schema.visibleWidgetIds, contains('energyUsed'));
    final energyTile =
        schema.tiles.whereType<ThermostatDailyEnergyTileSpec>().single;
    expect(
      energyTile.telemetryHistoryIntent?.configuredSeriesKeys,
      const <String>[TelemetryHistoryMetricCatalog.powerMeterEnergyWhDelta],
    );
  });

  test('hides empty-control energy tile when telemetry is unreadable', () {
    final bundle = _bundle(
      widgets: const <Map<String, dynamic>>[
        {
          'id': 'energyUsed',
          'control_ids': <String>[],
        },
      ],
      controls: const <Map<String, dynamic>>[],
      readableDomains: const <String>{},
    );

    final schema = builder.build(bundle: bundle);

    expect(schema.visibleWidgetIds, isNot(contains('energyUsed')));
    expect(schema.tiles.whereType<ThermostatDailyEnergyTileSpec>(), isEmpty);
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
