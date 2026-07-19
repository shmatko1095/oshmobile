import 'package:oshmobile/features/telemetry_history/domain/models/heating_usage.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_usage_query.dart';

abstract interface class HeatingUsageReader {
  Future<HeatingUsage> getHeatingUsage({required TelemetryUsageQuery query});
}
