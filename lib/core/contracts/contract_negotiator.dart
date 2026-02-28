import 'package:oshmobile/core/contracts/device_contracts_models.dart';

class AppContractCapability {
  final List<String> readSchemas;
  final List<String> patchSchemas;
  final List<String> setSchemas;
  final Set<String> features;

  const AppContractCapability({
    this.readSchemas = const <String>[],
    this.patchSchemas = const <String>[],
    this.setSchemas = const <String>[],
    this.features = const <String>{},
  });
}

class ContractNegotiator {
  const ContractNegotiator();

  static const Map<String, AppContractCapability> appSupport =
      <String, AppContractCapability>{
    'device': AppContractCapability(
      readSchemas: <String>['device_state@1'],
    ),
    'settings': AppContractCapability(
      readSchemas: <String>['settings@1'],
      patchSchemas: <String>['settings@1'],
      setSchemas: <String>['settings@1'],
      features: <String>{
        'display.language',
        'control.model',
        'control.maxFloorTemp',
        'control.maxFloorTempLimitEnabled',
        'control.maxFloorTempFailSafe',
      },
    ),
    'sensors': AppContractCapability(
      readSchemas: <String>['sensors@1'],
      patchSchemas: <String>['sensors@1'],
      setSchemas: <String>['sensors@1'],
      features: <String>{
        'rename',
        'set_ref',
        'set_temp_calibration',
        'remove',
      },
    ),
    'schedule': AppContractCapability(
      readSchemas: <String>['schedule@1'],
      patchSchemas: <String>['schedule@1'],
      setSchemas: <String>['schedule@1'],
      features: <String>{'range-mode'},
    ),
    'telemetry': AppContractCapability(
      readSchemas: <String>['telemetry@1'],
    ),
    'diag': AppContractCapability(
      readSchemas: <String>['diag@1'],
    ),
  };

  NegotiatedContractSet negotiate(DeviceContractsSnapshot deviceSnapshot) {
    final domains = <String, NegotiatedContractDomain>{};

    for (final entry in appSupport.entries) {
      final domain = entry.key;
      final app = entry.value;
      final device = deviceSnapshot.capability(domain);

      domains[domain] = NegotiatedContractDomain(
        domain: domain,
        readSchema: _pickHighest(app.readSchemas, device.readSchemas),
        patchSchema: _pickHighest(app.patchSchemas, device.patchSchemas),
        setSchema: _pickHighest(app.setSchemas, device.setSchemas),
        features: app.features.intersection(device.features),
      );
    }

    return NegotiatedContractSet(domains: Map.unmodifiable(domains));
  }

  NegotiatedContractSet legacyFallback() {
    final domains = <String, NegotiatedContractDomain>{};
    for (final entry in appSupport.entries) {
      final app = entry.value;
      domains[entry.key] = NegotiatedContractDomain(
        domain: entry.key,
        readSchema: _pickHighest(app.readSchemas, app.readSchemas),
        patchSchema: _pickHighest(app.patchSchemas, app.patchSchemas),
        setSchema: _pickHighest(app.setSchemas, app.setSchemas),
        features: app.features,
      );
    }
    return NegotiatedContractSet(
      domains: Map.unmodifiable(domains),
      legacyFallback: true,
    );
  }

  NegotiatedContractSet legacyFallbackConservative() {
    final domains = <String, NegotiatedContractDomain>{};
    for (final entry in appSupport.entries) {
      final app = entry.value;
      domains[entry.key] = NegotiatedContractDomain(
        domain: entry.key,
        readSchema: _pickHighest(app.readSchemas, app.readSchemas),
        // Conservative legacy mode never assumes write support or feature flags.
        features: const <String>{},
      );
    }
    return NegotiatedContractSet(
      domains: Map.unmodifiable(domains),
      legacyFallback: true,
    );
  }

  String? _pickHighest(List<String> appSchemas, List<String> deviceSchemas) {
    final intersection = appSchemas
        .where(deviceSchemas.contains)
        .toList(growable: false)
      ..sort((a, b) => _majorOf(b).compareTo(_majorOf(a)));
    return intersection.isEmpty ? null : intersection.first;
  }

  int _majorOf(String schema) {
    final index = schema.lastIndexOf('@');
    if (index == -1 || index == schema.length - 1) return -1;
    return int.tryParse(schema.substring(index + 1)) ?? -1;
  }
}
