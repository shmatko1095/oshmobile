final class UpdateMyDeviceUserDataRequest {
  const UpdateMyDeviceUserDataRequest({
    required this.alias,
    required this.description,
  });

  final String alias;
  final String description;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'alias': alias,
        'description': description,
      };
}
