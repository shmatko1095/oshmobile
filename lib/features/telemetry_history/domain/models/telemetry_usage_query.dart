import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_usage_bucket.dart';

class TelemetryUsageQuery {
  const TelemetryUsageQuery.summary({
    required this.from,
    required this.to,
  })  : bucket = null,
        timezone = null;

  factory TelemetryUsageQuery.bucketed({
    required DateTime from,
    required DateTime to,
    required TelemetryUsageBucket bucket,
    required String timezone,
  }) {
    if (timezone.trim().isEmpty) {
      throw ArgumentError.value(
        timezone,
        'timezone',
        'Bucketed usage queries require an IANA time zone.',
      );
    }
    return TelemetryUsageQuery._(
      from: from,
      to: to,
      bucket: bucket,
      timezone: timezone,
    );
  }

  const TelemetryUsageQuery._({
    required this.from,
    required this.to,
    required this.bucket,
    required this.timezone,
  });

  final DateTime from;
  final DateTime to;
  final TelemetryUsageBucket? bucket;
  final String? timezone;
}
