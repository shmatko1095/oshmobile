import 'package:oshmobile/features/devices/details/domain/repositories/telemetry_repository.dart';

class SubscribeTelemetry {
  final TelemetryRepository repo;

  const SubscribeTelemetry(this.repo);

  Future<void> call() => repo.subscribe();
}
