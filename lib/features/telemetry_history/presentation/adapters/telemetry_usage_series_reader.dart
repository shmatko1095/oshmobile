import 'package:oshmobile/core/contracts/device_time_zone_reader.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/energy_usage_reader.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/heating_usage_reader.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/telemetry_history_series_reader.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_api_version.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_point.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_usage_bucket.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_usage_query.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_usage_series_summary.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_metric_catalog.dart';

class TelemetryUsageSeriesReader implements TelemetryHistorySeriesReader {
  const TelemetryUsageSeriesReader({
    required EnergyUsageReader energyReader,
    required HeatingUsageReader heatingReader,
    required DeviceTimeZoneReader timeZoneReader,
  })  : _energyReader = energyReader,
        _heatingReader = heatingReader,
        _timeZoneReader = timeZoneReader;

  final EnergyUsageReader _energyReader;
  final HeatingUsageReader _heatingReader;
  final DeviceTimeZoneReader _timeZoneReader;

  @override
  Future<TelemetryHistorySeries> getSeries({
    required String seriesKey,
    required DateTime from,
    required DateTime to,
    String preferredResolution = 'auto',
    TelemetryHistoryApiVersion apiVersion = TelemetryHistoryApiVersion.v1,
  }) async {
    if (seriesKey != TelemetryHistoryMetricCatalog.energyUsage &&
        seriesKey != TelemetryHistoryMetricCatalog.heatingUsage) {
      throw ArgumentError.value(
        seriesKey,
        'seriesKey',
        'Unsupported usage metric.',
      );
    }
    final timezone = await _timeZoneReader.readIanaTimeZone();
    final query = TelemetryUsageQuery.bucketed(
      from: from,
      to: to,
      bucket: _bucketFor(from, to),
      timezone: timezone,
    );
    if (seriesKey == TelemetryHistoryMetricCatalog.energyUsage) {
      final usage = await _energyReader.getEnergyUsage(query: query);
      return TelemetryHistorySeries(
        deviceId: usage.deviceId,
        serial: usage.serial,
        seriesKey: seriesKey,
        resolution: usage.bucket,
        from: usage.from,
        to: usage.to,
        points: usage.points
            .map(
              (point) => TelemetryHistoryPoint(
                bucketStart: point.from,
                samplesCount: point.energyKwh == null ? 0 : 1,
                sumValue: point.energyKwh,
                coverageRatio: point.coverageRatio,
              ),
            )
            .toList(growable: false),
        usageSummary: TelemetryUsageSeriesSummary(
          coverageRatio: usage.coverageRatio,
          availableFrom: usage.availableFrom,
          total: usage.totalKwh,
          average: usage.averageBucketKwh,
          peak: usage.peakBucketKwh,
        ),
      );
    }
    if (seriesKey == TelemetryHistoryMetricCatalog.heatingUsage) {
      final usage = await _heatingReader.getHeatingUsage(query: query);
      return TelemetryHistorySeries(
        deviceId: usage.deviceId,
        serial: usage.serial,
        seriesKey: seriesKey,
        resolution: usage.bucket,
        from: usage.from,
        to: usage.to,
        points: usage.points
            .map(
              (point) => TelemetryHistoryPoint(
                bucketStart: point.from,
                samplesCount: point.loadFactorPercent == null ? 0 : 1,
                lastNumericValue: point.loadFactorPercent,
                coverageRatio: point.coverageRatio,
              ),
            )
            .toList(growable: false),
        usageSummary: TelemetryUsageSeriesSummary(
          coverageRatio: usage.coverageRatio,
          availableFrom: usage.availableFrom,
          average: usage.loadFactorPercent,
          minimum: usage.minBucketPercent,
          maximum: usage.maxBucketPercent,
        ),
      );
    }
    throw StateError('Validated usage series key was not handled.');
  }

  TelemetryUsageBucket _bucketFor(DateTime from, DateTime to) {
    final duration = to.toUtc().difference(from.toUtc());
    if (duration <= const Duration(days: 1, hours: 1)) {
      return TelemetryUsageBucket.hour;
    }
    if (duration <= const Duration(days: 31, hours: 1)) {
      return TelemetryUsageBucket.day;
    }
    return TelemetryUsageBucket.month;
  }
}
