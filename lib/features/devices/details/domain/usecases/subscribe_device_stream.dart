import '../repositories/device_telemetry_repository.dart';

class SubscribeDeviceStreamUseCase {
  final DeviceTelemetryRepository repo;

  const SubscribeDeviceStreamUseCase(this.repo);

  Future<void> call(String deviceId) => repo.subscribe(deviceId);
}

class UnsubscribeDeviceStreamUseCase {
  final DeviceTelemetryRepository repo;

  const UnsubscribeDeviceStreamUseCase(this.repo);

  Future<void> call(String deviceId) => repo.unsubscribe(deviceId);
}

class GetDeviceStreamUseCase {
  final DeviceTelemetryRepository repo;

  const GetDeviceStreamUseCase(this.repo);

  Stream<Map<String, dynamic>> call(String deviceId) => repo.stream(deviceId);
}
