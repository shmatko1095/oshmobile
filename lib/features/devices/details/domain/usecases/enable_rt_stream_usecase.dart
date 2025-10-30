import '../repositories/device_control_repository.dart';

class EnableRtStreamUseCase {
  final DeviceControlRepository repo;

  const EnableRtStreamUseCase(this.repo);

  Future<void> call(String deviceId, {Duration interval = const Duration(seconds: 1)}) {
    return repo.enableRtStreaming(deviceId, interval: interval);
  }
}

class DisableRtStreamUseCase {
  final DeviceControlRepository repo;

  const DisableRtStreamUseCase(this.repo);

  Future<void> call(String deviceId) => repo.disableRtStreaming(deviceId);
}
