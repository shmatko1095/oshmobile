import 'package:oshmobile/core/configuration/control_registry.dart';
import 'package:oshmobile/core/configuration/models/model_configuration.dart';

class RuntimeContractRecord {
  final String domain;
  final String contractId;
  final Map<String, dynamic> definition;

  const RuntimeContractRecord({
    required this.domain,
    required this.contractId,
    required this.definition,
  });

  factory RuntimeContractRecord.fromJson(Map<String, dynamic> json) {
    final rawDefinition = json['definition'];
    return RuntimeContractRecord(
      domain: json['domain']?.toString() ?? '',
      contractId: json['contract_id']?.toString() ?? '',
      definition: _asMap(rawDefinition),
    );
  }
}

class RuntimeFirmwareVersion {
  final int major;
  final int minor;

  const RuntimeFirmwareVersion({
    required this.major,
    required this.minor,
  });

  factory RuntimeFirmwareVersion.fromJson(Map<String, dynamic> json) {
    return RuntimeFirmwareVersion(
      major: (json['major'] as num?)?.toInt() ?? 0,
      minor: (json['minor'] as num?)?.toInt() ?? 0,
    );
  }
}

class RuntimeFirmwareCompatibility {
  final RuntimeFirmwareVersion from;
  final RuntimeFirmwareVersion? to;

  const RuntimeFirmwareCompatibility({
    required this.from,
    this.to,
  });

  factory RuntimeFirmwareCompatibility.fromJson(Map<String, dynamic> json) {
    final from = RuntimeFirmwareVersion.fromJson(_asMap(json['from']));
    final rawTo = json['to'];
    return RuntimeFirmwareCompatibility(
      from: from,
      to: rawTo is Map ? RuntimeFirmwareVersion.fromJson(_asMap(rawTo)) : null,
    );
  }
}

class DeviceConfigurationBundle {
  final String configurationId;
  final String modelId;
  final int revision;
  final String status;
  final String firmwareVersion;
  final RuntimeFirmwareCompatibility? firmwareCompatibility;
  final Map<String, RuntimeContractRecord> runtimeContractsByDomain;
  final Map<String, RuntimeContractRecord> runtimeContractsById;
  final Set<String> readableDomains;
  final Set<String> patchableDomains;
  final ModelConfiguration configuration;

  const DeviceConfigurationBundle({
    required this.configurationId,
    required this.modelId,
    required this.revision,
    required this.status,
    required this.firmwareVersion,
    this.firmwareCompatibility,
    required this.runtimeContractsByDomain,
    required this.runtimeContractsById,
    this.readableDomains = const <String>{},
    this.patchableDomains = const <String>{},
    required this.configuration,
  });

  factory DeviceConfigurationBundle.fromJson(Map<String, dynamic> json) {
    final configuration = ModelConfiguration.fromJson(
      _asMap(json['configuration']),
    );
    final domainByContractId = <String, String>{
      for (final entry in configuration.oshmobile.domains.entries)
        entry.value.contractId: entry.key,
    };

    final byDomain = <String, RuntimeContractRecord>{};
    final byId = <String, RuntimeContractRecord>{};

    void appendContracts(dynamic rawContracts) {
      if (rawContracts is! List) return;
      for (final raw in rawContracts) {
        if (raw is! Map) continue;
        final record = RuntimeContractRecord.fromJson(
          raw.cast<String, dynamic>(),
        );
        if (record.contractId.isEmpty) continue;

        final domain = record.domain.isNotEmpty
            ? record.domain
            : (domainByContractId[record.contractId] ?? '');
        if (domain.isEmpty) continue;

        final normalized = RuntimeContractRecord(
          domain: domain,
          contractId: record.contractId,
          definition: record.definition,
        );

        byDomain[domain] = normalized;
        byId.putIfAbsent(record.contractId, () => normalized);
      }
    }

    appendContracts(json['runtime_contracts']);
    if (byDomain.isEmpty) {
      // Legacy backend format support: [{"contract_id","definition"}]
      appendContracts(json['mqtt_contracts']);
    }

    final rawFirmwareCompatibility = json['firmware_compatibility'];

    return DeviceConfigurationBundle(
      configurationId: json['configuration_id']?.toString() ?? '',
      modelId: json['model_id']?.toString() ?? '',
      revision: (json['revision'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? '',
      firmwareVersion: json['firmware_version']?.toString() ?? '',
      firmwareCompatibility: rawFirmwareCompatibility is Map
          ? RuntimeFirmwareCompatibility.fromJson(
              _asMap(rawFirmwareCompatibility))
          : null,
      runtimeContractsByDomain: Map.unmodifiable(byDomain),
      runtimeContractsById: Map.unmodifiable(byId),
      configuration: configuration,
    );
  }

  DeviceConfigurationBundle copyWith({
    String? configurationId,
    String? modelId,
    int? revision,
    String? status,
    String? firmwareVersion,
    RuntimeFirmwareCompatibility? firmwareCompatibility,
    Map<String, RuntimeContractRecord>? runtimeContractsByDomain,
    Map<String, RuntimeContractRecord>? runtimeContractsById,
    Set<String>? readableDomains,
    Set<String>? patchableDomains,
    ModelConfiguration? configuration,
  }) {
    return DeviceConfigurationBundle(
      configurationId: configurationId ?? this.configurationId,
      modelId: modelId ?? this.modelId,
      revision: revision ?? this.revision,
      status: status ?? this.status,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      firmwareCompatibility:
          firmwareCompatibility ?? this.firmwareCompatibility,
      runtimeContractsByDomain:
          runtimeContractsByDomain ?? this.runtimeContractsByDomain,
      runtimeContractsById: runtimeContractsById ?? this.runtimeContractsById,
      readableDomains: readableDomains ?? this.readableDomains,
      patchableDomains: patchableDomains ?? this.patchableDomains,
      configuration: configuration ?? this.configuration,
    );
  }

  String get layout => configuration.oshmobile.layout;

  ConfigurationWidget? widget(String widgetId) =>
      configuration.oshmobile.widgets[widgetId];

  ConfigurationControl? control(String controlId) =>
      configuration.oshmobile.controls[controlId];

  ConfigurationDomainContract? domainContract(String domain) =>
      configuration.oshmobile.domains[domain];

  RuntimeContractRecord? resolvedContract(String domain) {
    final direct = runtimeContractsByDomain[domain];
    if (direct != null) return direct;

    final contractId = domainContract(domain)?.contractId;
    if (contractId == null || contractId.isEmpty) return null;
    return runtimeContractsById[contractId];
  }

  bool canReadDomain(String domain) => readableDomains.contains(domain);

  bool canPatchDomain(String domain) => patchableDomains.contains(domain);

  bool canRenderWidget(String widgetId) {
    final widget = this.widget(widgetId);
    if (widget == null) return false;
    final registry = ControlRegistry(this);
    return widget.controlIds.every(registry.canRead);
  }
}

Map<String, dynamic> _asMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  return const <String, dynamic>{};
}
