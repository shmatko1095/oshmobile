import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_point.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_setpoint_history.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_setpoint_point.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_setpoint_quality.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_setpoint_state.dart';
import 'package:oshmobile/features/telemetry_history/presentation/cubit/telemetry_history_state.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_metric.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_range.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_slide_view_model.dart';
import 'package:oshmobile/generated/l10n.dart';

TelemetryHistorySeries _series({
  required String seriesKey,
  required List<TelemetryHistoryPoint> points,
}) {
  final from = DateTime.utc(2026, 3, 14, 0);
  return TelemetryHistorySeries(
    deviceId: 'd',
    serial: 'sn',
    seriesKey: seriesKey,
    resolution: '5m',
    from: from,
    to: from.add(const Duration(days: 1)),
    points: points,
  );
}

void main() {
  final s = S();

  test('builds energy bar model with hourly average for day range', () {
    const metric = TelemetryHistoryMetric(
      title: 'Energy used',
      seriesKey: 'power_meter.energy_wh_delta',
      kind: TelemetryHistoryMetricKind.numeric,
      unit: 'kWh',
      fractionDigits: 3,
      useSumValue: true,
      valueMultiplier: 0.001,
      displayMode: TelemetryHistoryMetricDisplayMode.energyDelta,
    );
    final series = _series(
      seriesKey: metric.seriesKey,
      points: <TelemetryHistoryPoint>[
        TelemetryHistoryPoint(
          bucketStart: DateTime.utc(2026, 3, 14, 1),
          samplesCount: 1,
          sumValue: 420,
        ),
        TelemetryHistoryPoint(
          bucketStart: DateTime.utc(2026, 3, 14, 2),
          samplesCount: 1,
          sumValue: 580,
        ),
      ],
    );
    final state = TelemetryHistoryState.initial(
      metrics: const <TelemetryHistoryMetric>[metric],
      initialMetricIndex: 0,
      initialRange: TelemetryHistoryRange.day,
    ).copyWith(
      seriesBySeriesKey: <String, TelemetryHistorySeries>{
        metric.seriesKey: series,
      },
    );

    final model = TelemetryHistorySlideModelBuilder.build(
      state: state,
      metric: metric,
      enabledTemperatureSeries: const <String>{},
      s: s,
    );

    expect(model.chartKind, TelemetryHistorySlideChartKind.energyBar);
    expect(model.chartValues, <double>[0.42, 0.58]);
    expect(model.chartTimestamps, hasLength(2));
    expect(model.summaryItems.map((item) => item.label), <String>[
      'Total',
      'Avg / hour',
      'Peak interval',
    ]);
    expect(model.summaryItems.map((item) => item.value), <String>[
      '1.000 kWh',
      '0.042 kWh',
      '0.580 kWh',
    ]);
  });

  test('builds temperature overlay model from selected comparison toggles', () {
    const metric = TelemetryHistoryMetric(
      title: 'Temperature',
      seriesKey: 'climate_sensors.floor.temp',
      kind: TelemetryHistoryMetricKind.numeric,
      unit: '°C',
      sensorId: 'floor',
    );
    const heatingMetric = TelemetryHistoryMetric(
      title: 'Heating',
      seriesKey: 'heater_enabled',
      kind: TelemetryHistoryMetricKind.boolean,
    );
    final from = DateTime.utc(2026, 3, 14, 1);
    final state = TelemetryHistoryState.initial(
      metrics: const <TelemetryHistoryMetric>[metric],
      comparisonMetrics: const <TelemetryHistoryMetric>[heatingMetric],
      initialMetricIndex: 0,
      initialRange: TelemetryHistoryRange.day,
    ).copyWith(
      seriesBySeriesKey: <String, TelemetryHistorySeries>{
        metric.seriesKey: _series(
          seriesKey: metric.seriesKey,
          points: <TelemetryHistoryPoint>[
            TelemetryHistoryPoint(
              bucketStart: from,
              samplesCount: 1,
              avgValue: 21,
              maxValue: 22,
              minValue: 20,
              referenceSensorId: 'floor',
            ),
          ],
        ),
        heatingMetric.seriesKey: _series(
          seriesKey: heatingMetric.seriesKey,
          points: <TelemetryHistoryPoint>[
            TelemetryHistoryPoint(
              bucketStart: from,
              samplesCount: 1,
              trueRatio: 1,
            ),
          ],
        ),
      },
      setpointHistory: TelemetrySetpointHistory(
        deviceId: 'd',
        serial: 'sn',
        resolution: '5m',
        from: from,
        to: from.add(const Duration(days: 1)),
        points: <TelemetrySetpointPoint>[
          TelemetrySetpointPoint(
            bucketStart: from,
            observedAt: from,
            state: const TelemetrySetpointState.temperature(20),
            quality: TelemetrySetpointQuality.exact,
          ),
        ],
      ),
    );

    final model = TelemetryHistorySlideModelBuilder.build(
      state: state,
      metric: metric,
      enabledTemperatureSeries: const <String>{
        TelemetryHistorySlideModelBuilder.targetSeriesId,
        TelemetryHistorySlideModelBuilder.heatingSeriesId,
      },
      s: s,
    );

    expect(
      model.chartKind,
      TelemetryHistorySlideChartKind.temperatureOverlay,
    );
    expect(model.overlayOptions.map((option) => option.id), <String>[
      TelemetryHistorySlideModelBuilder.heatingSeriesId,
      TelemetryHistorySlideModelBuilder.targetSeriesId,
    ]);
    expect(model.selectedOverlayIds, {
      TelemetryHistorySlideModelBuilder.targetSeriesId,
      TelemetryHistorySlideModelBuilder.heatingSeriesId,
    });
    expect(model.overlaySeries.map((series) => series.id), <String>[
      TelemetryHistorySlideModelBuilder.temperatureSeriesId,
      TelemetryHistorySlideModelBuilder.heatingSeriesId,
      TelemetryHistorySlideModelBuilder.targetSeriesId,
    ]);
    expect(model.overlaySeries.first.fill, isTrue);
    expect(model.overlaySeries.first.fillTopAlpha, 0.32);
    expect(model.overlaySeries.first.fillBottomAlpha, 0.07);
    expect(model.overlaySeries[1].points.single.value, 1);
    expect(model.overlaySeries[1].points.single.displayValue, 1);
    expect(model.overlaySeries[1].includeInYAxisRange, isFalse);
    expect(model.overlaySeries[1].activityBand, isNotNull);
    expect(model.hasTemperatureAxisSeries, isTrue);
    expect(model.isEmpty, isFalse);
  });

  test('maps ON above 40°C and OFF to the bottom target marker', () {
    const metric = TelemetryHistoryMetric(
      title: 'Temperature',
      seriesKey: 'climate_sensors.floor.temp',
      kind: TelemetryHistoryMetricKind.numeric,
      unit: '°C',
      sensorId: 'floor',
    );
    const heatingMetric = TelemetryHistoryMetric(
      title: 'Heating',
      seriesKey: 'heater_enabled',
      kind: TelemetryHistoryMetricKind.boolean,
    );
    final from = DateTime.utc(2026, 3, 14, 1);
    final state = TelemetryHistoryState.initial(
      metrics: const <TelemetryHistoryMetric>[metric],
      comparisonMetrics: const <TelemetryHistoryMetric>[heatingMetric],
      initialMetricIndex: 0,
      initialRange: TelemetryHistoryRange.day,
    ).copyWith(
      seriesBySeriesKey: <String, TelemetryHistorySeries>{
        metric.seriesKey: _series(
          seriesKey: metric.seriesKey,
          points: <TelemetryHistoryPoint>[
            TelemetryHistoryPoint(
              bucketStart: from,
              samplesCount: 1,
              avgValue: 21,
            ),
          ],
        ),
      },
      setpointHistory: TelemetrySetpointHistory(
        deviceId: 'd',
        serial: 'sn',
        resolution: '5m',
        from: from,
        to: from.add(const Duration(days: 1)),
        points: <TelemetrySetpointPoint>[
          TelemetrySetpointPoint(
            bucketStart: from,
            observedAt: from,
            state: const TelemetrySetpointState.on(),
            quality: TelemetrySetpointQuality.exact,
          ),
          TelemetrySetpointPoint(
            bucketStart: from.add(const Duration(minutes: 5)),
            observedAt: from.add(const Duration(minutes: 5)),
            state: const TelemetrySetpointState.off(),
            quality: TelemetrySetpointQuality.exact,
          ),
        ],
      ),
    );

    final model = TelemetryHistorySlideModelBuilder.build(
      state: state,
      metric: metric,
      enabledTemperatureSeries: const <String>{
        TelemetryHistorySlideModelBuilder.targetSeriesId,
      },
      s: s,
    );

    final targetSeries = model.overlaySeries.singleWhere(
      (series) => series.id == TelemetryHistorySlideModelBuilder.targetSeriesId,
    );

    expect(targetSeries.isStepLine, isTrue);
    expect(targetSeries.points.map((point) => point.value), <double?>[41, 0]);
    expect(
      targetSeries.points.map((point) => point.timestamp),
      <DateTime>[from, from.add(const Duration(minutes: 5))],
    );
    expect(targetSeries.points.first.tooltipText, 'ON');
    expect(targetSeries.points.last.tooltipText, 'OFF');
    expect(targetSeries.points.first.includeInYAxisRange, isTrue);
    expect(targetSeries.points.last.includeInYAxisRange, isFalse);
    expect(targetSeries.points.last.axisFraction, 0.02);
    expect(model.chartSemanticLabel, 'Temperature. Target: OFF');
  });

  test('announces one localized inactive target state', () {
    const metric = TelemetryHistoryMetric(
      title: 'Temperature',
      seriesKey: 'climate_sensors.floor.temp',
      kind: TelemetryHistoryMetricKind.numeric,
      unit: '°C',
      sensorId: 'floor',
    );
    const heatingMetric = TelemetryHistoryMetric(
      title: 'Heating',
      seriesKey: 'heater_enabled',
      kind: TelemetryHistoryMetricKind.boolean,
    );
    final from = DateTime.utc(2026, 3, 14, 1);
    final state = TelemetryHistoryState.initial(
      metrics: const <TelemetryHistoryMetric>[metric],
      comparisonMetrics: const <TelemetryHistoryMetric>[heatingMetric],
      initialMetricIndex: 0,
      initialRange: TelemetryHistoryRange.day,
    ).copyWith(
      setpointHistory: TelemetrySetpointHistory(
        deviceId: 'd',
        serial: 'sn',
        resolution: '5m',
        from: from,
        to: from.add(const Duration(days: 1)),
        points: <TelemetrySetpointPoint>[
          TelemetrySetpointPoint(
            bucketStart: from,
            observedAt: from,
            state: const TelemetrySetpointState.inactive(),
            quality: TelemetrySetpointQuality.exact,
          ),
        ],
      ),
    );

    final model = TelemetryHistorySlideModelBuilder.build(
      state: state,
      metric: metric,
      enabledTemperatureSeries: const <String>{
        TelemetryHistorySlideModelBuilder.targetSeriesId,
      },
      s: s,
    );

    expect(model.chartSemanticLabel, 'Temperature. Target: inactive');
    final target = model.overlaySeries.singleWhere(
      (series) => series.id == TelemetryHistorySlideModelBuilder.targetSeriesId,
    );
    expect(target.points.single.value, isNull);
  });
}
