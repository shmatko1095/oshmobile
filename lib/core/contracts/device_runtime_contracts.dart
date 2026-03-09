import 'package:oshmobile/core/configuration/models/device_configuration_bundle.dart';
import 'package:oshmobile/core/contracts/json_rpc_contract_descriptor.dart';

class RuntimeDomainContract {
  final JsonRpcContractDescriptor read;
  final JsonRpcContractDescriptor patch;
  final JsonRpcContractDescriptor set;
  final Map<String, dynamic>? stateSchema;
  final Map<String, dynamic>? patchSchema;
  final Map<String, dynamic>? setSchema;

  const RuntimeDomainContract({
    required this.read,
    required this.patch,
    required this.set,
    required this.stateSchema,
    required this.patchSchema,
    required this.setSchema,
  });

  String get methodDomain => read.methodDomain;

  String get schemaDomain => read.schemaDomain;

  String method(String op) => read.method(op);
}

class RuntimeContractsApplyResult {
  final Set<String> readableDomains;
  final Set<String> patchableDomains;
  final List<String> missingContracts;
  final List<String> unsupportedContracts;

  const RuntimeContractsApplyResult({
    required this.readableDomains,
    required this.patchableDomains,
    required this.missingContracts,
    required this.unsupportedContracts,
  });
}

class DeviceRuntimeContracts {
  DeviceRuntimeContracts() {
    reset();
  }

  static final RegExp _schemaRefRe = RegExp(r'^([A-Za-z0-9_]+)@([0-9]+)$');

  late Map<String, RuntimeDomainContract> _contracts;

  RuntimeDomainContract get settings => domain('settings');

  RuntimeDomainContract get sensors => domain('sensors');

  RuntimeDomainContract get telemetry => domain('telemetry');

  RuntimeDomainContract get schedule => domain('schedule');

  RuntimeDomainContract get device => domain('device');

  RuntimeDomainContract get diag => domain('diag');

  RuntimeDomainContract domain(String name) {
    final contract = _contracts[name];
    if (contract == null) {
      throw StateError(
        'Runtime mqtt contract for domain $name is not resolved from the backend bundle',
      );
    }
    return contract;
  }

  void reset() {
    _contracts = <String, RuntimeDomainContract>{};
  }

  RuntimeContractsApplyResult applyRuntimeBundle(
      DeviceConfigurationBundle bundle) {
    final next = <String, RuntimeDomainContract>{};

    final readableDomains = <String>{};
    final patchableDomains = <String>{};
    final missingContracts = <String>[];
    final unsupportedContracts = <String>[];

    for (final entry in bundle.configuration.oshmobile.domains.entries) {
      final domain = entry.key;
      final contractId = entry.value.contractId;
      if (contractId.isEmpty) {
        unsupportedContracts.add('$domain:<empty-contract-id>');
        continue;
      }

      final contractRecord = bundle.resolvedContract(domain);
      if (contractRecord == null) {
        missingContracts.add('$domain:$contractId');
        continue;
      }

      final parsed = _parseDefinition(
        definition: contractRecord.definition,
      );
      if (parsed == null || parsed.domain != domain) {
        unsupportedContracts.add('$domain:$contractId');
        continue;
      }

      next[domain] = RuntimeDomainContract(
        read: parsed.read ?? parsed.descriptor,
        patch: parsed.patch ?? parsed.descriptor,
        set: parsed.set ?? parsed.descriptor,
        stateSchema: parsed.stateSchema,
        patchSchema: parsed.patchSchema,
        setSchema: parsed.setSchema,
      );

      if (parsed.read != null) readableDomains.add(domain);
      if (parsed.patch != null) patchableDomains.add(domain);
    }

    _contracts = Map<String, RuntimeDomainContract>.unmodifiable(next);

    return RuntimeContractsApplyResult(
      readableDomains: Set<String>.unmodifiable(readableDomains),
      patchableDomains: Set<String>.unmodifiable(patchableDomains),
      missingContracts: List<String>.unmodifiable(missingContracts),
      unsupportedContracts: List<String>.unmodifiable(unsupportedContracts),
    );
  }

  _ParsedSchemaRef? _parseSchemaRef(String schemaRef) {
    final match = _schemaRefRe.firstMatch(schemaRef);
    if (match == null) return null;

    final schemaDomain = match.group(1);
    final majorRaw = match.group(2);
    if (schemaDomain == null || majorRaw == null) return null;

    final major = int.tryParse(majorRaw);
    if (major == null) return null;

    return _ParsedSchemaRef(
      schemaDomain: schemaDomain,
      major: major,
    );
  }

  _ParsedContractDefinition? _parseDefinition({
    required Map<String, dynamic> definition,
  }) {
    if (definition.isEmpty) {
      return null;
    }

    final methodDomain = _string(definition['domain']);
    final schemaRef = _string(definition['schema']);
    if (methodDomain == null || schemaRef == null) {
      return null;
    }

    final schemaRefParsed = _parseSchemaRef(schemaRef);
    if (schemaRefParsed == null) {
      return null;
    }

    final descriptor = JsonRpcContractDescriptor(
      methodDomain: methodDomain,
      schemaDomain: schemaRefParsed.schemaDomain,
      major: schemaRefParsed.major,
    );

    final wire = _stringKeyedMap(definition['wire']);
    final stateSchema = _schemaObject(wire['state']);
    final patchSchema = _schemaObject(wire['patch']);
    final setSchema = _schemaObject(wire['set']);

    final read = stateSchema != null ? descriptor : null;
    final patch = patchSchema != null ? descriptor : null;
    final set = setSchema != null ? descriptor : null;
    if (read == null && patch == null && set == null) {
      return null;
    }

    return _ParsedContractDefinition(
      domain: methodDomain,
      descriptor: descriptor,
      read: read,
      patch: patch,
      set: set,
      stateSchema: stateSchema,
      patchSchema: patchSchema,
      setSchema: setSchema,
    );
  }

  String? _string(dynamic raw) {
    if (raw == null) return null;
    final value = raw.toString();
    if (value.isEmpty) return null;
    return value;
  }

  Map<String, dynamic> _stringKeyedMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return const <String, dynamic>{};
  }

  Map<String, dynamic>? _schemaObject(dynamic raw) {
    if (raw is Map<String, dynamic> && raw.isNotEmpty) {
      return raw;
    }
    if (raw is Map && raw.isNotEmpty) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }
}

class _ParsedContractDefinition {
  final String domain;
  final JsonRpcContractDescriptor descriptor;
  final JsonRpcContractDescriptor? read;
  final JsonRpcContractDescriptor? patch;
  final JsonRpcContractDescriptor? set;
  final Map<String, dynamic>? stateSchema;
  final Map<String, dynamic>? patchSchema;
  final Map<String, dynamic>? setSchema;

  const _ParsedContractDefinition({
    required this.domain,
    required this.descriptor,
    this.read,
    this.patch,
    this.set,
    required this.stateSchema,
    required this.patchSchema,
    required this.setSchema,
  });
}

class _ParsedSchemaRef {
  final String schemaDomain;
  final int major;

  const _ParsedSchemaRef({
    required this.schemaDomain,
    required this.major,
  });
}
