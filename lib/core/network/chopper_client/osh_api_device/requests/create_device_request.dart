final class CreateDeviceRequest {
  final String serialNumber;
  final String secureCode;
  final String password;
  final String modelId;

  CreateDeviceRequest({
    required this.serialNumber,
    required this.secureCode,
    required this.password,
    required this.modelId,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'serialNumber': serialNumber,
        'secureCode': secureCode,
        'password': password,
        'modelId': modelId,
      };
}
