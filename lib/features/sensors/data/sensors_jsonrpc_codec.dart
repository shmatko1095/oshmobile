import 'package:oshmobile/core/contracts/bundled_contract_defaults.dart';

class SensorsJsonRpcCodec {
  // Legacy v1 defaults kept only for tests and compatibility helpers.
  static final _contract = BundledContractDefaults.v1.sensors;

  static String get schema => _contract.schema;
  static String get domain => _contract.methodDomain;

  static String methodOf(String op) => _contract.method(op);

  static String get methodState => methodOf('state');
  static String get methodGet => methodOf('get');
  static String get methodSet => methodOf('set');
  static String get methodPatch => methodOf('patch');
}
