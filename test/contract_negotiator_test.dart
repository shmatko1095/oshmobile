import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/contracts/contract_negotiator.dart';
import 'package:oshmobile/core/contracts/device_contracts_models.dart';

void main() {
  test('contract negotiator intersects app and device support', () {
    const negotiator = ContractNegotiator();
    final device = DeviceContractsSnapshot(
      domains: const <String, DeviceContractsDomainCapability>{
        'settings': DeviceContractsDomainCapability(
          readSchemas: <String>['settings@1', 'settings@2'],
          patchSchemas: <String>['settings@1'],
          setSchemas: <String>['settings@1'],
          features: <String>{'display.language', 'unknown.future'},
        ),
        'schedule': DeviceContractsDomainCapability(
          readSchemas: <String>['schedule@1'],
          patchSchemas: <String>['schedule@1'],
          setSchemas: <String>['schedule@1'],
          features: <String>{'range-mode'},
        ),
      },
    );

    final negotiated = negotiator.negotiate(device);

    expect(negotiated.domain('settings').readSchema, 'settings@1');
    expect(negotiated.domain('settings').patchSchema, 'settings@1');
    expect(negotiated.supportsFeature('settings', 'display.language'), isTrue);
    expect(negotiated.supportsFeature('settings', 'unknown.future'), isFalse);
    expect(negotiated.domain('schedule').setSchema, 'schedule@1');
  });

  test('legacy fallback exposes built-in v1 contracts', () {
    const negotiator = ContractNegotiator();

    final fallback = negotiator.legacyFallback();

    expect(fallback.legacyFallback, isTrue);
    expect(fallback.domain('telemetry').readSchema, 'telemetry@1');
    expect(fallback.domain('settings').patchSchema, 'settings@1');
  });
}
