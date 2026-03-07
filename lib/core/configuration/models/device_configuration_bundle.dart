import 'package:oshmobile/core/configuration/control_registry.dart';
import 'package:oshmobile/core/configuration/models/model_configuration.dart';

class RuntimeMqttContractRecord {
  final String contractId;
  final Map<String, dynamic> definition;

  const RuntimeMqttContractRecord({
    required this.contractId,
    required this.definition,
  });

  factory RuntimeMqttContractRecord.fromJson(Map<String, dynamic> json) {
    final rawDefinition = json['definition'];
    return RuntimeMqttContractRecord(
      contractId: json['contract_id']?.toString() ?? '',
      definition: _asMap(rawDefinition),
    );
  }
}

class DeviceConfigurationBundle {
  final String configurationId;
  final String modelId;
  final int revision;
  final String status;
  final String firmwareVersion;
  final Map<String, RuntimeMqttContractRecord> mqttContracts;
  final Set<String> readableDomains;
  final Set<String> patchableDomains;
  final ModelConfiguration configuration;

  const DeviceConfigurationBundle({
    required this.configurationId,
    required this.modelId,
    required this.revision,
    required this.status,
    required this.firmwareVersion,
    required this.mqttContracts,
    this.readableDomains = const <String>{},
    this.patchableDomains = const <String>{},
    required this.configuration,
  });

  factory DeviceConfigurationBundle.fromJson(Map<String, dynamic> json) {
    final contracts = <String, RuntimeMqttContractRecord>{};
    final rawContracts = json['mqtt_contracts'];
    if (rawContracts is List) {
      for (final raw in rawContracts) {
        if (raw is! Map) continue;
        final record = RuntimeMqttContractRecord.fromJson(
          raw.cast<String, dynamic>(),
        );
        if (record.contractId.isEmpty) continue;
        contracts[record.contractId] = record;
      }
    }

    return DeviceConfigurationBundle(
      configurationId: json['configuration_id']?.toString() ?? '',
      modelId: json['model_id']?.toString() ?? '',
      revision: (json['revision'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? '',
      firmwareVersion: json['firmware_version']?.toString() ?? '',
      mqttContracts: Map.unmodifiable(contracts),
      configuration: ModelConfiguration.fromJson(
        _asMap(json['configuration']),
      ),
    );
  }

  DeviceConfigurationBundle copyWith({
    String? configurationId,
    String? modelId,
    int? revision,
    String? status,
    String? firmwareVersion,
    Map<String, RuntimeMqttContractRecord>? mqttContracts,
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
      mqttContracts: mqttContracts ?? this.mqttContracts,
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

  RuntimeMqttContractRecord? resolvedContract(String domain) {
    final contractId = domainContract(domain)?.contractId;
    if (contractId == null || contractId.isEmpty) return null;
    return mqttContracts[contractId];
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
