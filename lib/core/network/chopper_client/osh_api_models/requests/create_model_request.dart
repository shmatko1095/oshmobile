final class CreateModelRequest {
  final String name;
  final String manufacturerId;
  final String configurationId;

  CreateModelRequest({
    required this.name,
    required this.manufacturerId,
    required this.configurationId,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'manufacturerId': manufacturerId,
        'configurationId': configurationId,
      };
}
