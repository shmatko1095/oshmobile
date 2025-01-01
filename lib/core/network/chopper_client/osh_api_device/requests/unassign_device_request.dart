final class UnassignDeviceRequest {
  final String sn;

  UnassignDeviceRequest({
    required this.sn,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'sn': sn,
      };
}
