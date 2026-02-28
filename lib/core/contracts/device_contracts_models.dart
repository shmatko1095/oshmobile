class DeviceContractsDomainCapability {
  final List<String> readSchemas;
  final List<String> patchSchemas;
  final List<String> setSchemas;
  final Set<String> features;

  const DeviceContractsDomainCapability({
    this.readSchemas = const <String>[],
    this.patchSchemas = const <String>[],
    this.setSchemas = const <String>[],
    this.features = const <String>{},
  });

  factory DeviceContractsDomainCapability.fromJson(Map<String, dynamic> json) {
    return DeviceContractsDomainCapability(
      readSchemas: _asStringList(json['readSchemas']),
      patchSchemas: _asStringList(json['patchSchemas']),
      setSchemas: _asStringList(json['setSchemas']),
      features: _asStringList(json['features']).toSet(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'readSchemas': readSchemas,
      'patchSchemas': patchSchemas,
      'setSchemas': setSchemas,
      'features': features.toList(growable: false),
    };
  }

  static List<String> _asStringList(dynamic value) {
    if (value is! List) return const <String>[];
    return value.map((item) => item.toString()).toList(growable: false);
  }
}

class DeviceContractsSnapshot {
  final Map<String, DeviceContractsDomainCapability> domains;

  const DeviceContractsSnapshot({
    required this.domains,
  });

  factory DeviceContractsSnapshot.fromJson(Map<String, dynamic> json) {
    final rawDomains = json['domains'];
    if (rawDomains is! Map) {
      throw const FormatException('Invalid contracts@1 payload');
    }

    const requiredDomains = <String>{
      'device',
      'settings',
      'sensors',
      'schedule',
      'telemetry',
      'diag',
    };

    final domains = <String, DeviceContractsDomainCapability>{};
    rawDomains.forEach((key, value) {
      if (value is! Map) return;
      domains[key.toString()] = DeviceContractsDomainCapability.fromJson(
        value.cast<String, dynamic>(),
      );
    });

    if (!requiredDomains.every(domains.containsKey)) {
      throw const FormatException('Invalid contracts@1 payload');
    }

    return DeviceContractsSnapshot(domains: Map.unmodifiable(domains));
  }

  DeviceContractsDomainCapability capability(String domain) {
    return domains[domain] ?? const DeviceContractsDomainCapability();
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'domains': domains.map((key, value) => MapEntry(key, value.toJson())),
    };
  }
}

class NegotiatedContractDomain {
  final String domain;
  final String? readSchema;
  final String? patchSchema;
  final String? setSchema;
  final Set<String> features;

  const NegotiatedContractDomain({
    required this.domain,
    this.readSchema,
    this.patchSchema,
    this.setSchema,
    this.features = const <String>{},
  });

  bool get readable => readSchema != null;
  bool get patchable => patchSchema != null;
  bool get settable => setSchema != null;
  bool get writable => patchable || settable;

  bool supportsFeature(String feature) => features.contains(feature);
}

class NegotiatedContractSet {
  final Map<String, NegotiatedContractDomain> domains;
  final bool legacyFallback;

  const NegotiatedContractSet({
    required this.domains,
    this.legacyFallback = false,
  });

  NegotiatedContractDomain domain(String name) {
    return domains[name] ??
        NegotiatedContractDomain(
          domain: name,
        );
  }

  bool canRead(String domainName) => domain(domainName).readable;
  bool canPatch(String domainName) => domain(domainName).patchable;
  bool canSet(String domainName) => domain(domainName).settable;
  bool supportsFeature(String domainName, String feature) =>
      domain(domainName).supportsFeature(feature);

  Set<String> get allSchemas {
    final out = <String>{};
    for (final item in domains.values) {
      if (item.readSchema != null) out.add(item.readSchema!);
      if (item.patchSchema != null) out.add(item.patchSchema!);
      if (item.setSchema != null) out.add(item.setSchema!);
    }
    return out;
  }
}
