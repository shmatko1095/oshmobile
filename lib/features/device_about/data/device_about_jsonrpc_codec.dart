import 'package:oshmobile/core/contracts/osh_contracts.dart';

class DeviceAboutJsonRpcCodec {
  static final _contract = OshContracts.current.deviceState;

  static String get schema => _contract.schema;
  static String get domain => _contract.methodDomain;

  static String methodOf(String op) => _contract.method(op);

  static String get methodState => methodOf('state');

  static String get methodGet => methodOf('get');

  static String get methodSet => methodOf('set');

  static String get methodPatch => methodOf('patch');
}
