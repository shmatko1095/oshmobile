import 'package:oshmobile/features/telemetry_history/domain/models/energy_usage.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_usage_query.dart';

abstract interface class EnergyUsageReader {
  Future<EnergyUsage> getEnergyUsage({required TelemetryUsageQuery query});
}
