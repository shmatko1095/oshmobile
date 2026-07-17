import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/utils/thermostat_heating_state.dart';

void main() {
  test('parses supported thermostat heating boolean values', () {
    expect(parseThermostatHeatingState(true), isTrue);
    expect(parseThermostatHeatingState(1), isTrue);
    expect(parseThermostatHeatingState('true'), isTrue);
    expect(parseThermostatHeatingState(' TRUE '), isTrue);
    expect(parseThermostatHeatingState('1'), isTrue);

    expect(parseThermostatHeatingState(false), isFalse);
    expect(parseThermostatHeatingState(0), isFalse);
    expect(parseThermostatHeatingState('false'), isFalse);
    expect(parseThermostatHeatingState(' FALSE '), isFalse);
    expect(parseThermostatHeatingState('0'), isFalse);
  });

  test('keeps missing and invalid heating values unknown', () {
    expect(parseThermostatHeatingState(null), isNull);
    expect(parseThermostatHeatingState(2), isNull);
    expect(parseThermostatHeatingState(-1), isNull);
    expect(parseThermostatHeatingState('on'), isNull);
    expect(parseThermostatHeatingState('unknown'), isNull);
    expect(parseThermostatHeatingState(const <String, dynamic>{}), isNull);
  });
}
