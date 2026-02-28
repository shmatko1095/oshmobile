/// JSON-RPC contract descriptor for one domain/schema pair.
///
/// - [methodDomain] is used in JSON-RPC method names: `<methodDomain>.<op>`
/// - [schemaDomain] is used in meta.schema: `<schemaDomain>@<major>`
///
/// In most cases these domains are equal. Example exception:
/// - methods: `device.get`
/// - schema: `device_state@1`
class JsonRpcContractDescriptor {
  final String methodDomain;
  final String schemaDomain;
  final int major;

  const JsonRpcContractDescriptor({
    required this.methodDomain,
    required this.schemaDomain,
    required this.major,
  });

  const JsonRpcContractDescriptor.same({
    required String domain,
    required this.major,
  })  : methodDomain = domain,
        schemaDomain = domain;

  String get schema => '$schemaDomain@$major';

  String method(String op) => '$methodDomain.$op';
}

/// Static v1 contract defaults bundled with the app.
///
/// Production runtime should prefer device-scoped negotiated contracts from
/// `DeviceRuntimeContracts`. These descriptors remain useful for:
/// - bootstrapping before negotiation completes
/// - tests and compatibility helpers
class BundledContractSet {
  final JsonRpcContractDescriptor settings;
  final JsonRpcContractDescriptor sensors;
  final JsonRpcContractDescriptor telemetry;
  final JsonRpcContractDescriptor schedule;
  final JsonRpcContractDescriptor deviceState;
  final JsonRpcContractDescriptor diag;

  const BundledContractSet({
    required this.settings,
    required this.sensors,
    required this.telemetry,
    required this.schedule,
    required this.deviceState,
    required this.diag,
  });

  const BundledContractSet.v1()
      : settings = const JsonRpcContractDescriptor.same(
          domain: 'settings',
          major: 1,
        ),
        sensors = const JsonRpcContractDescriptor.same(
          domain: 'sensors',
          major: 1,
        ),
        telemetry = const JsonRpcContractDescriptor.same(
          domain: 'telemetry',
          major: 1,
        ),
        schedule = const JsonRpcContractDescriptor.same(
          domain: 'schedule',
          major: 1,
        ),
        deviceState = const JsonRpcContractDescriptor(
          methodDomain: 'device',
          schemaDomain: 'device_state',
          major: 1,
        ),
        diag = const JsonRpcContractDescriptor.same(
          domain: 'diag',
          major: 1,
        );
}

/// Conservative bundled defaults shipped with the app binary.
class BundledContractDefaults {
  static const BundledContractSet v1 = BundledContractSet.v1();
}
