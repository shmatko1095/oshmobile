import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_aggregate_series.dart';

class TelemetryAggregate {
  const TelemetryAggregate({
    required this.deviceId,
    required this.serial,
    required this.resolution,
    required this.from,
    required this.to,
    required this.series,
  });

  final String deviceId;
  final String serial;
  final String resolution;
  final DateTime from;
  final DateTime to;
  final List<TelemetryAggregateSeries> series;
}
