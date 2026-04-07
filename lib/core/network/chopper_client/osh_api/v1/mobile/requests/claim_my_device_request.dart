final class ClaimMyDeviceRequest {
  const ClaimMyDeviceRequest({
    required this.secureCode,
  });

  final String secureCode;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'sc': secureCode,
      };
}
