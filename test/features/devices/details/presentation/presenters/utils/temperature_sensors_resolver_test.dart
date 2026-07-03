import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/utils/temperature_sensors_resolver.dart';

void main() {
  test('resolves stale temperature as display-only', () {
    final resolver = TemperatureSensorsResolver();

    final sensors = resolver.resolve([
      {
        'id': 'floor',
        'name': 'Floor',
        'ref': true,
        'kind': 'floor',
        'temp_valid': false,
        'temp_stale': true,
        'temp': 24.5,
        'humidity_valid': false,
      },
    ]);

    expect(sensors, hasLength(1));
    expect(sensors.first.id, 'floor');
    expect(sensors.first.tempValid, isFalse);
    expect(sensors.first.tempStale, isTrue);
    expect(sensors.first.hasTemperature, isTrue);
    expect(sensors.first.temp, 24.5);
  });

  test('drops temperature when neither fresh nor stale', () {
    final resolver = TemperatureSensorsResolver();

    final sensors = resolver.resolve([
      {
        'id': 'floor',
        'temp_valid': false,
        'temp_stale': false,
        'temp': 24.5,
        'humidity_valid': false,
      },
    ]);

    expect(sensors, hasLength(1));
    expect(sensors.first.tempValid, isFalse);
    expect(sensors.first.tempStale, isFalse);
    expect(sensors.first.hasTemperature, isFalse);
    expect(sensors.first.temp, isNull);
  });
}
