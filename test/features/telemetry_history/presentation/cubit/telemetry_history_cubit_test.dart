import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/telemetry_history_series_reader.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_api_version.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_point.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';
import 'package:oshmobile/features/telemetry_history/presentation/cubit/telemetry_history_cubit.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_metric.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_range.dart';

class _Request {
  _Request({
    required this.seriesKey,
    required this.from,
    required this.to,
    required this.completer,
  });

  final String seriesKey;
  final DateTime from;
  final DateTime to;
  final Completer<TelemetryHistorySeries> completer;
}

class _QueuedTelemetryHistoryApi implements TelemetryHistorySeriesReader {
  final List<_Request> requests = <_Request>[];

  @override
  Future<TelemetryHistorySeries> getSeries({
    required String seriesKey,
    required DateTime from,
    required DateTime to,
    String preferredResolution = 'auto',
    TelemetryHistoryApiVersion apiVersion = TelemetryHistoryApiVersion.v1,
  }) {
    final completer = Completer<TelemetryHistorySeries>();
    requests.add(
      _Request(
        seriesKey: seriesKey,
        from: from,
        to: to,
        completer: completer,
      ),
    );
    return completer.future;
  }
}

TelemetryHistorySeries _series({
  required String seriesKey,
  required DateTime from,
  required DateTime to,
  required double value,
}) {
  return TelemetryHistorySeries(
    deviceId: 'd',
    serial: 'sn',
    seriesKey: seriesKey,
    resolution: '5m',
    from: from,
    to: to,
    points: <TelemetryHistoryPoint>[
      TelemetryHistoryPoint(
        bucketStart: from,
        samplesCount: 1,
        avgValue: value,
      ),
    ],
  );
}

void main() {
  test('ignores stale response when range changed quickly', () async {
    final api = _QueuedTelemetryHistoryApi();
    final now = DateTime.utc(2026, 3, 14, 20, 18, 40);
    final cubit = TelemetryHistoryCubit(
      seriesReader: api,
      metrics: const <TelemetryHistoryMetric>[
        TelemetryHistoryMetric(
          title: 'Temperature',
          seriesKey: 'climate_sensors.floor.temp',
          kind: TelemetryHistoryMetricKind.numeric,
          unit: '°C',
        ),
      ],
      nowUtc: () => now,
    );

    unawaited(cubit.load());
    await Future<void>.delayed(Duration.zero);
    expect(api.requests, hasLength(1));

    unawaited(cubit.selectRange(TelemetryHistoryRange.week));
    await Future<void>.delayed(Duration.zero);
    expect(api.requests, hasLength(2));

    final fastRequest = api.requests[1];
    fastRequest.completer.complete(
      _series(
        seriesKey: fastRequest.seriesKey,
        from: fastRequest.from,
        to: fastRequest.to,
        value: 31.0,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    final staleRequest = api.requests[0];
    staleRequest.completer.complete(
      _series(
        seriesKey: staleRequest.seriesKey,
        from: staleRequest.from,
        to: staleRequest.to,
        value: 25.0,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.range, TelemetryHistoryRange.week);
    expect(cubit.state.series?.points.first.avgValue, 31.0);
    expect(cubit.state.errorMessage, isNull);
    expect(cubit.state.isLoading, isFalse);

    await cubit.close();
  });

  test('loads every displayed sensor once and reuses cache', () async {
    final api = _QueuedTelemetryHistoryApi();
    final now = DateTime.utc(2026, 3, 14, 20, 18, 40);
    final cubit = TelemetryHistoryCubit(
      seriesReader: api,
      metrics: const <TelemetryHistoryMetric>[
        TelemetryHistoryMetric(
          title: 'Temperature',
          seriesKey: 'climate_sensors.floor.temp',
          kind: TelemetryHistoryMetricKind.numeric,
          unit: '°C',
        ),
        TelemetryHistoryMetric(
          title: 'Temperature',
          seriesKey: 'climate_sensors.room.temp',
          kind: TelemetryHistoryMetricKind.numeric,
          unit: '°C',
        ),
      ],
      nowUtc: () => now,
    );

    unawaited(cubit.load());
    await Future<void>.delayed(Duration.zero);
    expect(api.requests, hasLength(2));
    expect(
      api.requests.map((request) => request.seriesKey).toSet(),
      <String>{
        'climate_sensors.floor.temp',
        'climate_sensors.room.temp',
      },
    );

    await cubit.selectMetricIndex(1);
    expect(api.requests, hasLength(2));

    for (final request in api.requests) {
      request.completer.complete(
        _series(
          seriesKey: request.seriesKey,
          from: request.from,
          to: request.to,
          value: request.seriesKey.endsWith('floor.temp') ? 27.0 : 23.5,
        ),
      );
    }
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.series?.points.first.avgValue, 23.5);
    await cubit.selectMetricIndex(0);
    expect(api.requests, hasLength(2));
    expect(cubit.state.series?.points.first.avgValue, 27.0);

    await cubit.close();
  });

  test('loads series-backed comparison metrics with temperature', () async {
    final api = _QueuedTelemetryHistoryApi();
    final now = DateTime.utc(2026, 3, 14, 20, 18, 40);
    final cubit = TelemetryHistoryCubit(
      seriesReader: api,
      metrics: const <TelemetryHistoryMetric>[
        TelemetryHistoryMetric(
          title: 'Temperature',
          seriesKey: 'climate_sensors.floor.temp',
          kind: TelemetryHistoryMetricKind.numeric,
          unit: '°C',
        ),
      ],
      comparisonMetrics: const <TelemetryHistoryMetric>[
        TelemetryHistoryMetric(
          title: 'Target',
          seriesKey: 'target_temp',
          kind: TelemetryHistoryMetricKind.numeric,
          unit: '°C',
        ),
        TelemetryHistoryMetric(
          title: 'Heating',
          seriesKey: 'heater_enabled',
          kind: TelemetryHistoryMetricKind.boolean,
        ),
      ],
      nowUtc: () => now,
    );

    unawaited(cubit.load());
    await Future<void>.delayed(Duration.zero);

    expect(api.requests, hasLength(2));
    expect(
      api.requests.map((request) => request.seriesKey).toSet(),
      {
        'climate_sensors.floor.temp',
        'heater_enabled',
      },
    );

    for (final request in api.requests) {
      request.completer.complete(
        _series(
          seriesKey: request.seriesKey,
          from: request.from,
          to: request.to,
          value: 1,
        ),
      );
    }
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.seriesBySeriesKey.keys.toSet(), {
      'climate_sensors.floor.temp',
      'heater_enabled',
    });

    await cubit.close();
  });

  test('ensureMetricsLoaded deduplicates by series key', () async {
    final api = _QueuedTelemetryHistoryApi();
    final now = DateTime.utc(2026, 3, 14, 20, 18, 40);
    final cubit = TelemetryHistoryCubit(
      seriesReader: api,
      metrics: const <TelemetryHistoryMetric>[
        TelemetryHistoryMetric(
          title: 'Temperature',
          seriesKey: 'climate_sensors.floor.temp',
          kind: TelemetryHistoryMetricKind.numeric,
          unit: '°C',
        ),
      ],
      nowUtc: () => now,
    );

    unawaited(
      cubit.ensureMetricsLoaded(
        const <TelemetryHistoryMetric>[
          TelemetryHistoryMetric(
            title: 'Target',
            seriesKey: 'target_temp',
            kind: TelemetryHistoryMetricKind.numeric,
            unit: '°C',
          ),
          TelemetryHistoryMetric(
            title: 'Target duplicate',
            seriesKey: 'target_temp',
            kind: TelemetryHistoryMetricKind.numeric,
            unit: '°C',
          ),
          TelemetryHistoryMetric(
            title: 'Heating',
            seriesKey: 'heater_enabled',
            kind: TelemetryHistoryMetricKind.boolean,
          ),
        ],
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(api.requests, hasLength(2));
    expect(
      api.requests.map((request) => request.seriesKey).toSet(),
      {'target_temp', 'heater_enabled'},
    );

    for (final request in api.requests) {
      request.completer.complete(
        _series(
          seriesKey: request.seriesKey,
          from: request.from,
          to: request.to,
          value: 1,
        ),
      );
    }
    await Future<void>.delayed(Duration.zero);

    await cubit.close();
  });

  test('custom range reloads each series once and restores exact preset window',
      () async {
    final api = _QueuedTelemetryHistoryApi();
    final now = DateTime(2026, 7, 17, 14, 30);
    final cubit = TelemetryHistoryCubit(
      seriesReader: api,
      metrics: const <TelemetryHistoryMetric>[
        TelemetryHistoryMetric(
          title: 'Temperature',
          seriesKey: 'climate_sensors.floor.temp',
          kind: TelemetryHistoryMetricKind.numeric,
          unit: '°C',
        ),
        TelemetryHistoryMetric(
          title: 'Voltage',
          seriesKey: 'power_meter.voltage',
          kind: TelemetryHistoryMetricKind.numeric,
          unit: 'V',
        ),
      ],
      nowLocal: () => now,
    );

    final previousFuture = cubit.showPreviousPeriod();
    await Future<void>.delayed(Duration.zero);
    expect(api.requests, hasLength(2));
    for (final request in api.requests) {
      request.completer.complete(
        _series(
          seriesKey: request.seriesKey,
          from: request.from,
          to: request.to,
          value: 1,
        ),
      );
    }
    await previousFuture;
    final presetWindow = cubit.state.window;

    final customFuture = cubit.selectCustomRange(
      startLocal: DateTime(2026, 7, 1),
      endInclusiveLocal: DateTime(2026, 7, 10),
    );
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.range, TelemetryHistoryRange.custom);
    expect(cubit.state.window.startLocal, DateTime(2026, 7, 1));
    expect(cubit.state.window.endLocal, DateTime(2026, 7, 11));
    expect(api.requests, hasLength(4));
    expect(
      api.requests.skip(2).map((request) => request.seriesKey).toSet(),
      {'climate_sensors.floor.temp', 'power_meter.voltage'},
    );
    for (final request in api.requests.skip(2)) {
      request.completer.complete(
        _series(
          seriesKey: request.seriesKey,
          from: request.from,
          to: request.to,
          value: 2,
        ),
      );
    }
    expect(await customFuture, isTrue);

    final clearFuture = cubit.clearCustomRange();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.range, TelemetryHistoryRange.day);
    expect(cubit.state.window.startLocal, presetWindow.startLocal);
    expect(cubit.state.window.endLocal, presetWindow.endLocal);
    expect(api.requests, hasLength(6));
    for (final request in api.requests.skip(4)) {
      expect(request.from, presetWindow.queryFromUtc);
      expect(request.to, presetWindow.queryToUtc(now));
      request.completer.complete(
        _series(
          seriesKey: request.seriesKey,
          from: request.from,
          to: request.to,
          value: 3,
        ),
      );
    }
    await clearFuture;

    await cubit.close();
  });

  test('rejects unavailable and future custom ranges without requests',
      () async {
    final api = _QueuedTelemetryHistoryApi();
    final now = DateTime(2026, 7, 17, 14, 30);
    final cubit = TelemetryHistoryCubit(
      seriesReader: api,
      metrics: const <TelemetryHistoryMetric>[
        TelemetryHistoryMetric(
          title: 'Temperature',
          seriesKey: 'climate_sensors.floor.temp',
          kind: TelemetryHistoryMetricKind.numeric,
          unit: '°C',
        ),
      ],
      nowLocal: () => now,
    );

    expect(
      await cubit.selectCustomRange(
        startLocal: now.subtract(const Duration(days: 371)),
        endInclusiveLocal: now,
      ),
      isFalse,
    );
    expect(
      await cubit.selectCustomRange(
        startLocal: now,
        endInclusiveLocal: now.add(const Duration(days: 1)),
      ),
      isFalse,
    );
    expect(cubit.state.range, TelemetryHistoryRange.day);
    expect(api.requests, isEmpty);

    await cubit.close();
  });
}
