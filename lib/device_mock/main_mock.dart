import 'mqtt_thermostat_mock.dart';

/// Standalone entry to run the mock as a Dart console app (flutter run -t lib/device_mock/main_mock.dart)
Future<void> main() async {
  final mock = MqttThermostatMock(
    brokerHost: 'localhost',
    brokerPort: 1883,
    useWss: false,
    tenantId: 'dev',
    deviceId: 'abc123',
    username: null,
    password: null,
  );
  await mock.start();
  // Keep running
}
