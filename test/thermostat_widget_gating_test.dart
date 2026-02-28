import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/common/entities/device/known_device_models.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/thermostat_presenters.dart';
import 'support/thermostat_profile_bundle_fixture.dart';

void main() {
  test('T1A thermostat exposes only supported widget ids', () {
    final bundle = createThermostatProfileBundle(
      serial: 'TEST-SN',
      modelId: t1aFlWzeModelId,
      negotiatedSchemas: const <String>{
        'settings@1',
        'schedule@1',
        'telemetry@1',
        'sensors@1',
      },
    );

    final visible = ThermostatBasicPresenter.visibleWidgetIds(bundle);

    expect(
      visible,
      containsAll(const <String>[
        'heroTemperature',
        'modeBar',
        'heatingToggle',
        'loadFactor24h',
      ]),
    );
    expect(visible, isNot(contains('powerNow')));
    expect(visible, isNot(contains('inletTemp')));
    expect(visible, isNot(contains('outletTemp')));
    expect(visible, isNot(contains('deltaT')));
  });
}
