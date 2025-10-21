import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/features/home/domain/repositories/device_repository.dart';

// Пока без модели/конфига: вернём device и пустой конфиг-JSON.
// Когда подключишь Model/Configuration, расширим.
class GetDeviceFull {
  final DeviceRepository deviceRepository;

  GetDeviceFull(this.deviceRepository);

  Future<({Device device, Map<String, dynamic> configuration, String modelId})> call(String deviceId) async {
    final Either<Failure, Device> res = await deviceRepository.get(deviceId: deviceId);
    return await res.fold(
      (f) => Future.error(f.message ?? 'Failed to load device'),
      (d) async {
        // TODO: когда появится эндпойнт модели/конфига — подставь реальные данные
        final cfg = <String, dynamic>{
          'capabilities': ['sensor.temperature', 'setting.target_temperature', 'switch.heating'],
          'ui_hints': {
            'dashboard.order': ['currentTemp', 'targetTemp', 'heatingToggle', 'humidity'],
            'dashboard.hidden': [],
          }
        };
        return (device: d, configuration: cfg, modelId: d.modelId);
      },
    );
  }
}
