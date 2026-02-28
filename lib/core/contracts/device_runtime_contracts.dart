import 'package:oshmobile/core/contracts/device_contracts_models.dart';
import 'package:oshmobile/core/contracts/bundled_contract_defaults.dart';

class RuntimeDomainContract {
  final JsonRpcContractDescriptor read;
  final JsonRpcContractDescriptor patch;
  final JsonRpcContractDescriptor set;

  const RuntimeDomainContract({
    required this.read,
    required this.patch,
    required this.set,
  });

  String get methodDomain => read.methodDomain;
  String get schemaDomain => read.schemaDomain;

  String method(String op) => read.method(op);
}

class DeviceRuntimeContracts {
  DeviceRuntimeContracts({
    BundledContractSet defaults = BundledContractDefaults.v1,
  }) : _defaults = <String, JsonRpcContractDescriptor>{
          'settings': defaults.settings,
          'sensors': defaults.sensors,
          'telemetry': defaults.telemetry,
          'schedule': defaults.schedule,
          'device': defaults.deviceState,
          'diag': defaults.diag,
        } {
    reset();
  }

  static final RegExp _schemaRefRe = RegExp(r'^([A-Za-z0-9_]+)@([0-9]+)$');

  final Map<String, JsonRpcContractDescriptor> _defaults;
  late Map<String, RuntimeDomainContract> _contracts;

  RuntimeDomainContract get settings => domain('settings');
  RuntimeDomainContract get sensors => domain('sensors');
  RuntimeDomainContract get telemetry => domain('telemetry');
  RuntimeDomainContract get schedule => domain('schedule');
  RuntimeDomainContract get device => domain('device');
  RuntimeDomainContract get diag => domain('diag');

  RuntimeDomainContract domain(String name) {
    return _contracts[name] ?? _fallbackDomain(name);
  }

  void reset() {
    _contracts = <String, RuntimeDomainContract>{
      for (final entry in _defaults.entries)
        entry.key: RuntimeDomainContract(
          read: entry.value,
          patch: entry.value,
          set: entry.value,
        ),
    };
  }

  void applyNegotiated(NegotiatedContractSet negotiated) {
    _contracts = <String, RuntimeDomainContract>{
      for (final entry in _defaults.entries)
        entry.key: _resolveDomain(
          domain: entry.key,
          negotiated: negotiated.domain(entry.key),
        ),
    };
  }

  RuntimeDomainContract _resolveDomain({
    required String domain,
    required NegotiatedContractDomain negotiated,
  }) {
    final fallback = _defaults[domain]!;
    final read = _descriptorForSchema(
          domain: domain,
          schemaRef: negotiated.readSchema,
        ) ??
        fallback;
    final patch = _descriptorForSchema(
          domain: domain,
          schemaRef: negotiated.patchSchema ?? negotiated.readSchema,
        ) ??
        read;
    final set = _descriptorForSchema(
          domain: domain,
          schemaRef: negotiated.setSchema ??
              negotiated.patchSchema ??
              negotiated.readSchema,
        ) ??
        patch;

    return RuntimeDomainContract(
      read: read,
      patch: patch,
      set: set,
    );
  }

  RuntimeDomainContract _fallbackDomain(String domain) {
    final fallback = _defaults[domain]!;
    return RuntimeDomainContract(
      read: fallback,
      patch: fallback,
      set: fallback,
    );
  }

  JsonRpcContractDescriptor? _descriptorForSchema({
    required String domain,
    required String? schemaRef,
  }) {
    if (schemaRef == null || schemaRef.isEmpty) return null;

    final match = _schemaRefRe.firstMatch(schemaRef);
    if (match == null) return null;

    final schemaDomain = match.group(1);
    final majorRaw = match.group(2);
    if (schemaDomain == null || majorRaw == null) return null;

    final major = int.tryParse(majorRaw);
    if (major == null) return null;

    final fallback = _defaults[domain];
    return JsonRpcContractDescriptor(
      methodDomain: fallback?.methodDomain ?? schemaDomain,
      schemaDomain: schemaDomain,
      major: major,
    );
  }
}
