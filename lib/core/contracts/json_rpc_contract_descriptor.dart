class JsonRpcContractDescriptor {
  final String methodDomain;
  final String schemaDomain;
  final int major;

  const JsonRpcContractDescriptor({
    required this.methodDomain,
    required this.schemaDomain,
    required this.major,
  });

  String get schema => '$schemaDomain@$major';

  String method(String op) => '$methodDomain.$op';
}
