import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/telemetry_history_series_reader.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_api_version.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_point.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';
import 'package:oshmobile/features/telemetry_history/presentation/cubit/temperature_history_preview_cubit.dart';

class _CountingTelemetryHistoryApi implements TelemetryHistorySeriesReader {
  int calls = 0;

  @override
  Future<TelemetryHistorySeries> getSeries({
    required String seriesKey,
    required DateTime from,
    required DateTime to,
    String preferredResolution = 'auto',
    TelemetryHistoryApiVersion apiVersion = TelemetryHistoryApiVersion.v1,
  }) async {
    calls++;
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
          avgValue: 28.5,
        ),
      ],
    );
  }
}

void main() {
  test('uses cache and does not reload fresh preview', () async {
    final api = _CountingTelemetryHistoryApi();
    final now = DateTime.utc(2026, 3, 14, 20, 18, 40);
    final cubit = TemperatureHistoryPreviewCubit(
      seriesReader: api,
      cacheTtl: const Duration(minutes: 2),
      nowUtc: () => now,
    );

    await cubit.ensureLoaded(seriesKey: 'climate_sensors.floor.temp');
    await cubit.ensureLoaded(seriesKey: 'climate_sensors.floor.temp');

    expect(api.calls, 1);
    final entry = cubit.state.entryOf('climate_sensors.floor.temp');
    expect(entry, isNotNull);
    expect(entry!.values, hasLength(1));
    expect(entry.lastValue, 28.5);

    await cubit.close();
  });
}
