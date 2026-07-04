import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_point.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';
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
    const targetMetric = TelemetryHistoryMetric(
      title: 'Target',
      seriesKey: 'target_temp',
      kind: TelemetryHistoryMetricKind.numeric,
      unit: '°C',
    );
    const heatingMetric = TelemetryHistoryMetric(
      title: 'Heating',
      seriesKey: 'heater_enabled',
      kind: TelemetryHistoryMetricKind.boolean,
    );
    final from = DateTime.utc(2026, 3, 14, 1);
    final state = TelemetryHistoryState.initial(
      metrics: const <TelemetryHistoryMetric>[metric],
      comparisonMetrics: const <TelemetryHistoryMetric>[
        targetMetric,
        heatingMetric,
      ],
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
        targetMetric.seriesKey: _series(
          seriesKey: targetMetric.seriesKey,
          points: <TelemetryHistoryPoint>[
            TelemetryHistoryPoint(
              bucketStart: from,
              samplesCount: 1,
              avgValue: 20,
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
    expect(model.overlaySeries.first.fillTopAlpha, 0.26);
    expect(model.overlaySeries.first.fillBottomAlpha, 0.04);
    expect(model.overlaySeries[1].displayValues, <double>[1]);
    expect(model.hasTemperatureAxisSeries, isTrue);
    expect(model.isEmpty, isFalse);
  });
}
