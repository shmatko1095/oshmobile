import 'package:oshmobile/features/devices/details/domain/repositories/telemetry_repository.dart';

class UnsubscribeTelemetry {
  final TelemetryRepository repo;

  const UnsubscribeTelemetry(this.repo);

  Future<void> call(String deviceId) => repo.unsubscribe(deviceId);
}
