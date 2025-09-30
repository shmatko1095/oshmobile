final class UpdateDeviceUserData {
  final String alias;
  final String description;

  UpdateDeviceUserData({
    required this.alias,
    required this.description,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'alias': alias,
        'description': description,
      };
}
