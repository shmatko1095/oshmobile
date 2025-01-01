final class AssignDeviceRequest {
  final String sn;
  final String sc;

  AssignDeviceRequest({
    required this.sn,
    required this.sc,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'sn': sn,
        'sc': sc,
      };
}
