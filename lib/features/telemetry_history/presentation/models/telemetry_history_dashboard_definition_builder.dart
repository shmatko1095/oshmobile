import 'package:collection/collection.dart';
import 'package:oshmobile/app/device_session/domain/models/device_temperature_sensor_ref.dart';
import 'package:oshmobile/core/configuration/models/configuration_history.dart';
import 'package:oshmobile/core/configuration/models/configuration_history_series.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_dashboard_definition.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_metric.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_metric_catalog.dart';
import 'package:oshmobile/generated/l10n.dart';

TelemetryHistoryDashboardDefinition buildTelemetryHistoryDashboardDefinition({
  required ConfigurationHistory history,
  required List<DeviceTemperatureSensorRef> sensors,
  required S strings,
  String? initialSensorId,
}) {
  final metrics = <TelemetryHistoryMetric>[];
  final seenSeriesKeys = <String>{};
  var containsTemperature = false;
  var containsHeatingOverlay = false;
  var containsSetpointOverlay = false;

  for (final view in history.views) {
    for (final seriesId in view.seriesIds) {
      final series = history.series[seriesId];
      if (series == null) continue;

      if (_isTemperatureCollection(series)) {
        containsTemperature = true;
        for (final sensor in sensors) {
          final id = sensor.id.trim();
          if (id.isEmpty) continue;
          final seriesKey = 'climate_sensors.$id.temp';
          if (!seenSeriesKeys.add(seriesKey)) continue;
          metrics.add(
            TelemetryHistoryMetric(
              title: strings.TelemetryHistoryMetricTemperature,
              subtitle: sensor.name.trim().isEmpty ? id : sensor.name.trim(),
              seriesKey: seriesKey,
              kind: TelemetryHistoryMetricKind.numeric,
              unit: '°C',
              sensorId: id,
              isPrimarySensor: sensor.isReference,
            ),
          );
        }
        continue;
      }

      if (_isSetpointOverlay(series)) {
        containsSetpointOverlay = true;
        continue;
      }
      if (_isHeatingOverlay(series)) {
        containsHeatingOverlay = true;
        continue;
      }

      final metric = _metricForSeries(series, strings);
      if (metric == null || !seenSeriesKeys.add(metric.seriesKey)) continue;
      metrics.add(metric);
    }
  }

  final comparisonMetrics = <TelemetryHistoryMetric>[
    if (containsTemperature && containsSetpointOverlay)
      TelemetryHistoryMetricCatalog.targetTempMetric(strings),
    if (containsTemperature && containsHeatingOverlay)
      TelemetryHistoryMetricCatalog.heatingActivityMetric(strings),
  ];
  final normalizedInitialSensorId = initialSensorId?.trim();
  final initialSeriesKey =
      normalizedInitialSensorId == null || normalizedInitialSensorId.isEmpty
          ? null
          : 'climate_sensors.$normalizedInitialSensorId.temp';
  final initialMetricIndex = initialSeriesKey == null
      ? 0
      : metrics.indexWhere((metric) => metric.seriesKey == initialSeriesKey);

  return TelemetryHistoryDashboardDefinition(
    metrics: List<TelemetryHistoryMetric>.unmodifiable(metrics),
    comparisonMetrics:
        List<TelemetryHistoryMetric>.unmodifiable(comparisonMetrics),
    initialMetricIndex: initialMetricIndex < 0 ? 0 : initialMetricIndex,
  );
}

TelemetryHistoryMetric? _metricForSeries(
  ConfigurationHistorySeries series,
  S strings,
) {
  if (series.valueType != 'number' || series.path.trim().isEmpty) return null;
  final known = switch (series.path) {
    TelemetryHistoryMetricCatalog.loadFactor =>
      TelemetryHistoryMetricCatalog.loadFactorMetric(strings),
    TelemetryHistoryMetricCatalog.powerMeterEnergyWhDelta ||
    TelemetryHistoryMetricCatalog.powerMeterVoltageV ||
    TelemetryHistoryMetricCatalog.powerMeterCurrentA ||
    TelemetryHistoryMetricCatalog.powerMeterActivePowerW ||
    TelemetryHistoryMetricCatalog.powerMeterApparentPowerVa =>
      TelemetryHistoryMetricCatalog.powerMeterMetrics(
        strings,
        configuredSeriesKeys: <String>[series.path],
      ).firstOrNull,
    _ => null,
  };
  if (known != null) return known;

  return TelemetryHistoryMetric(
    title: series.title.trim().isEmpty ? series.path : series.title.trim(),
    seriesKey: series.path,
    kind: TelemetryHistoryMetricKind.numeric,
    unit: _normalizedUnit(series.unit),
  );
}

bool _isTemperatureCollection(ConfigurationHistorySeries series) {
  return series.path == 'climate_sensors.*.temp' &&
      series.valueType == 'number';
}

bool _isSetpointOverlay(ConfigurationHistorySeries series) {
  return switch (series.path) {
    'target_temp' => series.valueType == 'number',
    'setpoint_on' || 'setpoint_off' => series.valueType == 'boolean',
    _ => false,
  };
}

bool _isHeatingOverlay(ConfigurationHistorySeries series) {
  return series.path == TelemetryHistoryMetricCatalog.heaterEnabled &&
      series.valueType == 'boolean';
}

String _normalizedUnit(String unit) {
  final normalized = unit.trim();
  return normalized == 'C' ? '°C' : normalized;
}
