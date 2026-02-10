class SensorsJsonRpcCodec {
  static const String schema = 'sensors@1';
  static const String domain = 'sensors';

  static String methodOf(String op) => '$domain.$op';

  static String get methodState => methodOf('state');
  static String get methodGet => methodOf('get');
  static String get methodSet => methodOf('set');
  static String get methodPatch => methodOf('patch');
}
