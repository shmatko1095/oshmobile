import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_api_version.dart';

class TelemetryAggregateQuery {
  const TelemetryAggregateQuery({
    required this.seriesKeys,
    required this.from,
    required this.to,
    this.preferredResolution = 'auto',
    this.apiVersion = TelemetryHistoryApiVersion.v1,
  });

  final List<String> seriesKeys;
  final DateTime from;
  final DateTime to;
  final String preferredResolution;
  final TelemetryHistoryApiVersion apiVersion;
}
