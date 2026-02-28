import 'package:meta/meta.dart';
import 'package:oshmobile/core/contracts/bundled_contract_defaults.dart';

@immutable
class ContractSchemaRef {
  final String schemaDomain;
  final int major;

  const ContractSchemaRef({
    required this.schemaDomain,
    required this.major,
  });

  String get raw => '$schemaDomain@$major';
}

@immutable
class ContractRoute {
  final JsonRpcContractDescriptor descriptor;
  final String method;
  final String operation;

  const ContractRoute({
    required this.descriptor,
    required this.method,
    required this.operation,
  });
}

/// Contract registry for routing runtime JSON-RPC messages by:
/// - method domain (`<domain>.<op>`)
/// - schema in `params.meta.schema` (`<schemaDomain>@<major>`)
///
/// This is intentionally independent from topic names so it can be reused
/// across transport implementations.
abstract interface class ContractRegistry {
  ContractSchemaRef? parseSchemaRef(String? schemaRef);

  bool supportsSchema(String? schemaRef);

  JsonRpcContractDescriptor? resolveBySchemaDomain(String schemaDomain);

  JsonRpcContractDescriptor? resolveByMethodDomain(String methodDomain);

  ContractRoute? route({
    required String method,
    required String? schemaRef,
  });
}

class StaticContractRegistry implements ContractRegistry {
  StaticContractRegistry({
    required BundledContractSet contracts,
  }) : _descriptors = <JsonRpcContractDescriptor>[
          contracts.settings,
          contracts.sensors,
          contracts.telemetry,
          contracts.schedule,
          contracts.deviceState,
          contracts.diag,
        ] {
    for (final d in _descriptors) {
      _bySchemaDomain[d.schemaDomain] = d;
      _byMethodDomain[d.methodDomain] = d;
    }
  }

  factory StaticContractRegistry.bundledV1() => StaticContractRegistry(
        contracts: BundledContractDefaults.v1,
      );

  static final RegExp _schemaRe = RegExp(r'^([A-Za-z0-9_]+)@([0-9]+)$');
  static final RegExp _methodRe = RegExp(r'^([A-Za-z0-9_]+)\.([A-Za-z0-9_]+)$');

  final List<JsonRpcContractDescriptor> _descriptors;
  final Map<String, JsonRpcContractDescriptor> _bySchemaDomain =
      <String, JsonRpcContractDescriptor>{};
  final Map<String, JsonRpcContractDescriptor> _byMethodDomain =
      <String, JsonRpcContractDescriptor>{};

  @override
  ContractSchemaRef? parseSchemaRef(String? schemaRef) {
    if (schemaRef == null || schemaRef.isEmpty) return null;

    final match = _schemaRe.firstMatch(schemaRef);
    if (match == null) return null;

    final schemaDomain = match.group(1);
    final majorRaw = match.group(2);
    if (schemaDomain == null || majorRaw == null) return null;

    final major = int.tryParse(majorRaw);
    if (major == null) return null;

    return ContractSchemaRef(schemaDomain: schemaDomain, major: major);
  }

  @override
  bool supportsSchema(String? schemaRef) {
    final parsed = parseSchemaRef(schemaRef);
    if (parsed == null) return false;

    final d = resolveBySchemaDomain(parsed.schemaDomain);
    if (d == null) return false;

    return d.major == parsed.major;
  }

  @override
  JsonRpcContractDescriptor? resolveBySchemaDomain(String schemaDomain) {
    return _bySchemaDomain[schemaDomain];
  }

  @override
  JsonRpcContractDescriptor? resolveByMethodDomain(String methodDomain) {
    return _byMethodDomain[methodDomain];
  }

  @override
  ContractRoute? route({
    required String method,
    required String? schemaRef,
  }) {
    final schema = parseSchemaRef(schemaRef);
    if (schema == null) return null;

    final methodMatch = _methodRe.firstMatch(method);
    if (methodMatch == null) return null;

    final methodDomain = methodMatch.group(1);
    final operation = methodMatch.group(2);
    if (methodDomain == null || operation == null) return null;

    final fromSchema = resolveBySchemaDomain(schema.schemaDomain);
    if (fromSchema == null || fromSchema.major != schema.major) return null;

    if (fromSchema.methodDomain != methodDomain) return null;

    return ContractRoute(
      descriptor: fromSchema,
      method: method,
      operation: operation,
    );
  }

  List<JsonRpcContractDescriptor> allDescriptors() =>
      List<JsonRpcContractDescriptor>.unmodifiable(_descriptors);
}
