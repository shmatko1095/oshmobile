final class AssignDeviceRequest {
  final String sc;

  AssignDeviceRequest({
    required this.sc,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'sc': sc,
      };
}
