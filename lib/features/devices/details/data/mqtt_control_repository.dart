import 'package:oshmobile/core/network/mqtt/device_mqtt_repo.dart';
import 'package:oshmobile/core/network/mqtt/signal_command.dart';
import 'package:oshmobile/features/devices/details/domain/repositories/control_repository.dart';

/// MQTT commands implementation using cmd/inbox + {action: alias, value: ...}.
class MqttControlRepositoryImpl implements ControlRepository {
  MqttControlRepositoryImpl({
    required DeviceMqttRepo mqtt,
    required String tenantId,
    required String deviceSn,
  })  : _mqtt = mqtt,
        _tenantId = tenantId,
        _deviceSn = deviceSn;

  final DeviceMqttRepo _mqtt;
  final String _tenantId;
  final String _deviceSn;

  @override
  Future<void> send<T>(Command<T> cmd, T value, {String? corrId}) async {
    final topic = 'v1/tenants/$_tenantId/devices/$_deviceSn/cmd/inbox';
    await _mqtt.publishJson(
      topic,
      {
        'action': cmd.alias,
        'value': value,
        'corrId': corrId ?? DateTime.now().microsecondsSinceEpoch.toString(),
      },
    );
  }
}
