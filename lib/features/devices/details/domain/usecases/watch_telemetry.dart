import 'package:oshmobile/features/devices/details/domain/repositories/telemetry_repository.dart';

class WatchTelemetry {
  final TelemetryRepository repo;

  const WatchTelemetry(this.repo);

  /// Stream of alias-key diffs, e.g., {'hvac.targetC': 21.5}
  Stream<Map<String, dynamic>> call(String deviceId) => repo.watchAliases(deviceId);
}
