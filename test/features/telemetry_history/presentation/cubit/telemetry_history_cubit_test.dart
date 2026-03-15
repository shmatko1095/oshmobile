import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/telemetry_history_series_reader.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_api_version.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_point.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';
import 'package:oshmobile/features/telemetry_history/presentation/cubit/telemetry_history_cubit.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_metric.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_range.dart';

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

  test('loads another sensor on page switch and reuses cache', () async {
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
    expect(api.requests, hasLength(1));
    expect(api.requests.first.seriesKey, 'climate_sensors.floor.temp');

    api.requests.first.completer.complete(
      _series(
        seriesKey: api.requests.first.seriesKey,
        from: api.requests.first.from,
        to: api.requests.first.to,
        value: 27.0,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    unawaited(cubit.selectMetricIndex(1));
    await Future<void>.delayed(Duration.zero);
    expect(api.requests, hasLength(2));
    expect(api.requests[1].seriesKey, 'climate_sensors.room.temp');

    api.requests[1].completer.complete(
      _series(
        seriesKey: api.requests[1].seriesKey,
        from: api.requests[1].from,
        to: api.requests[1].to,
        value: 23.5,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    await cubit.selectMetricIndex(0);
    await Future<void>.delayed(Duration.zero);
    expect(api.requests, hasLength(2));
    expect(cubit.state.series?.points.first.avgValue, 27.0);

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
}
