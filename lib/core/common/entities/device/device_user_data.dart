class DeviceUserData {
  final String alias;
  final String description;

  const DeviceUserData({
    required this.alias,
    required this.description,
  });

  factory DeviceUserData.fromJson(Map<String, dynamic>? json) {
    json = json ?? {};
    return DeviceUserData(
      alias: json['alias'] ?? "",
      description: json['description'] ?? "",
    );
  }

//toJson, copyWith
}
