import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/app/device_session/domain/models/device_temperature_sensor_ref.dart';
import 'package:oshmobile/core/configuration/models/model_configuration.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_dashboard_definition_builder.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_metric_catalog.dart';
import 'package:oshmobile/generated/l10n.dart';

void main() {
  test('parses history series, axis and ordered views', () {
    final configuration = ModelConfiguration.fromJson(
      _configurationJson(
        views: const <Map<String, dynamic>>[
          {
            'id': 'temperature',
            'title': 'Temperature',
            'series_ids': ['climateTemp', 'missing', 'heater'],
          },
          {
            'id': 'power',
            'title': 'Power',
            'series_ids': ['activePower'],
          },
        ],
      ),
    );

    expect(configuration.history.series.keys, <String>[
      'climateTemp',
      'heater',
      'activePower',
      'integralEnergy',
    ]);
    expect(configuration.history.views.map((view) => view.id), <String>[
      'temperature',
      'power',
    ]);
    final temperature = configuration.history.series['climateTemp']!;
    expect(temperature.arrayIdField, 'id');
    expect(temperature.validField, 'temp_valid');
    expect(temperature.axis?.mode, 'auto');
    expect(temperature.axis?.min, 5);
    expect(temperature.axis?.max, 40);
  });

  test('missing or malformed history is parsed as empty', () {
    final missing = ModelConfiguration.fromJson(const <String, dynamic>{});
    final malformed = ModelConfiguration.fromJson(
      const <String, dynamic>{
        'integrations': {
          'history': {
            'series': 'invalid',
            'views': [
              {'id': '', 'series_ids': <String>[]},
              {'id': 'empty', 'series_ids': <String>[]},
            ],
          },
        },
      },
    );

    expect(missing.history.series, isEmpty);
    expect(missing.history.views, isEmpty);
    expect(malformed.history.series, isEmpty);
    expect(malformed.history.views, isEmpty);
  });

  test('dashboard order comes only from views and expands sensors', () async {
    final strings = await S.load(const Locale('en'));
    final configuration = ModelConfiguration.fromJson(
      _configurationJson(
        views: const <Map<String, dynamic>>[
          {
            'id': 'temperature',
            'series_ids': ['climateTemp', 'heater'],
          },
          {
            'id': 'power',
            'series_ids': ['activePower'],
          },
        ],
      ),
    );

    final definition = buildTelemetryHistoryDashboardDefinition(
      history: configuration.history,
      sensors: const <DeviceTemperatureSensorRef>[
        DeviceTemperatureSensorRef(
          id: 'air',
          name: 'Air',
          isReference: true,
        ),
        DeviceTemperatureSensorRef(
          id: 'floor',
          name: 'Floor',
          isReference: false,
        ),
      ],
      strings: strings,
      initialSensorId: 'floor',
    );

    expect(
      definition.metrics.map((metric) => metric.seriesKey),
      <String>[
        'climate_sensors.air.temp',
        'climate_sensors.floor.temp',
        TelemetryHistoryMetricCatalog.powerMeterActivePowerW,
      ],
    );
    expect(definition.initialMetricIndex, 1);
    expect(
      definition.comparisonMetrics.map((metric) => metric.seriesKey),
      <String>[TelemetryHistoryMetricCatalog.heaterEnabled],
    );
    expect(
      definition.metrics.map((metric) => metric.seriesKey),
      isNot(contains(TelemetryHistoryMetricCatalog.powerMeterEnergyWhDelta)),
    );
  });

  test('unknown value types and unreferenced series are ignored', () async {
    final strings = await S.load(const Locale('en'));
    final json = _configurationJson(
      views: const <Map<String, dynamic>>[
        {
          'id': 'unsupported',
          'series_ids': ['badPower', 'unknownId'],
        },
      ],
    );
    final integrations = json['integrations'] as Map<String, dynamic>;
    final history = integrations['history'] as Map<String, dynamic>;
    final series = history['series'] as List<Map<String, dynamic>>;
    series.add(const <String, dynamic>{
      'id': 'badPower',
      'path': 'power_meter.active_power_w',
      'value_type': 'text',
    });

    final configuration = ModelConfiguration.fromJson(json);
    final definition = buildTelemetryHistoryDashboardDefinition(
      history: configuration.history,
      sensors: const <DeviceTemperatureSensorRef>[],
      strings: strings,
    );

    expect(definition.isEmpty, isTrue);
    expect(
      configuration.history.series,
      contains('integralEnergy'),
    );
  });
}

Map<String, dynamic> _configurationJson({
  required List<Map<String, dynamic>> views,
}) {
  return <String, dynamic>{
    'schema_version': 1,
    'integrations': <String, dynamic>{
      'oshmobile': const <String, dynamic>{},
      'history': <String, dynamic>{
        'series': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'climateTemp',
            'title': 'Temperature',
            'path': 'climate_sensors.*.temp',
            'value_type': 'number',
            'unit': 'C',
            'array_id_field': 'id',
            'valid_field': 'temp_valid',
            'axis': const <String, dynamic>{
              'mode': 'auto',
              'min': 5,
              'max': 40,
            },
          },
          const <String, dynamic>{
            'id': 'heater',
            'title': 'Heating',
            'path': 'heater_enabled',
            'value_type': 'boolean',
          },
          const <String, dynamic>{
            'id': 'activePower',
            'title': 'Power',
            'path': 'power_meter.active_power_w',
            'value_type': 'number',
            'unit': 'W',
          },
          const <String, dynamic>{
            'id': 'integralEnergy',
            'title': 'Energy',
            'path': 'power_meter.energy_wh_delta',
            'value_type': 'number',
            'unit': 'Wh',
          },
        ],
        'views': views,
      },
    },
  };
}
