import 'package:oshmobile/features/telemetry_history/domain/models/energy_usage_point.dart';

class EnergyUsage {
  const EnergyUsage({
    required this.deviceId,
    required this.serial,
    required this.from,
    required this.to,
    required this.bucket,
    required this.timezone,
    required this.availableFrom,
    required this.coverageRatio,
    required this.totalKwh,
    required this.averageBucketKwh,
    required this.peakBucketKwh,
    required this.peakBucketFrom,
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
  final double? totalKwh;
  final double? averageBucketKwh;
  final double? peakBucketKwh;
  final DateTime? peakBucketFrom;
  final List<EnergyUsagePoint> points;
}
