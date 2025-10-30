import 'package:oshmobile/core/network/mqtt/device_mqtt_repo.dart';
import 'package:oshmobile/core/network/mqtt/signal_command.dart';
import 'package:oshmobile/features/devices/details/domain/repositories/control_repository.dart';

/// MQTT commands implementation using cmd/inbox + {action: alias, value: ...}.
class MqttControlRepositoryImpl implements ControlRepository {
  MqttControlRepositoryImpl(this._mqtt, this._tenantId);

  final DeviceMqttRepo _mqtt;
  final String _tenantId;

  @override
  Future<void> send<T>(String deviceId, Command<T> cmd, T value, {String? corrId}) async {
    final topic = 'v1/tenants/$_tenantId/devices/$deviceId/cmd/inbox';
    await _mqtt.publishJson(topic, {
      'action': cmd.alias,
      'value': value,
      'corrId': corrId ?? DateTime.now().microsecondsSinceEpoch.toString(),
      'ts': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
