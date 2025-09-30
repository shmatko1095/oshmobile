import 'package:oshmobile/features/home/domain/entities/user_device.dart';

class User {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final List<UserDevice> devices;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.devices,
  });

  factory User.fromJson(Map<String, dynamic>? json) {
    json = json ?? {};
    return User(
      id: json['id'],
      email: json['email'],
      firstName: json['firstName'] ?? "",
      lastName: json['lastName'],
      devices: (json['devices'] as List<dynamic>?)?.map((deviceJson) {
            return UserDevice.fromJson(deviceJson as Map<String, dynamic>);
          }).toList() ??
          [],
    );
  }
}
