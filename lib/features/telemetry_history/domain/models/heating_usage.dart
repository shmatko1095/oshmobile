import 'package:oshmobile/features/telemetry_history/domain/models/heating_usage_point.dart';

class HeatingUsage {
  const HeatingUsage({
    required this.deviceId,
    required this.serial,
    required this.from,
    required this.to,
    required this.bucket,
    required this.timezone,
    required this.availableFrom,
    required this.coverageRatio,
    required this.loadFactorPercent,
    required this.minBucketPercent,
    required this.maxBucketPercent,
    required this.points,
  });

  final String deviceId;
  final String serial;
  final DateTime from;
  final DateTime to;
  final String bucket;
  final String timezone;
  final DateTime? availableFrom;
  final double coverageRatio;
  final double? loadFactorPercent;
  final double? minBucketPercent;
  final double? maxBucketPercent;
  final List<HeatingUsagePoint> points;
}
