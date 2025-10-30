import 'package:oshmobile/core/network/mqtt/device_mqtt_repo.dart';
import 'package:oshmobile/features/devices/details/domain/repositories/device_control_repository.dart';

/// Sends control commands to device via MQTT.
class MqttDeviceControlRepository implements DeviceControlRepository {
  final DeviceMqttRepo _mqtt;

  MqttDeviceControlRepository(this._mqtt);

  @override
  Future<void> enableRtStreaming(String deviceId, {required Duration interval}) async {
    await _mqtt.publishCommand(
      deviceId,
      'telemetry.set_interval',
      args: {'seconds': interval.inSeconds},
    );
  }

  @override
  Future<void> disableRtStreaming(String deviceId) async {
    await _mqtt.publishCommand(
      deviceId,
      'telemetry.set_interval',
      args: {'seconds': 300},
    );
  }
}
