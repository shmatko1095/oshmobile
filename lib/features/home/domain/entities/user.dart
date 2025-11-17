import 'package:oshmobile/features/home/domain/entities/user_device.dart';

class User {
  final String id;
  final List<UserDevice> devices;

  User({
    required this.id,
    required this.devices,
  });

  factory User.fromJson(Map<String, dynamic>? json) {
    json = json ?? {};
    return User(
      id: json['id'],
      devices: (json['devices'] as List<dynamic>?)?.map((deviceJson) {
            return UserDevice.fromJson(deviceJson as Map<String, dynamic>);
          }).toList() ??
          [],
    );
  }
}
