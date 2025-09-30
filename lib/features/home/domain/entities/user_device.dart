class UserDevice {
  final String id;

  UserDevice({
    required this.id,
  });

  factory UserDevice.fromJson(Map<String, dynamic>? json) {
    json = json ?? {};
    return UserDevice(
      id: json['id'],
    );
  }
}
