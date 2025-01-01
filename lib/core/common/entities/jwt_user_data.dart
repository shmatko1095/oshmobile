class JwtUserData {
  final String uuid;
  final String email;
  final String name;
  final bool isAdmin;

  JwtUserData({
    required this.uuid,
    required this.email,
    required this.name,
    required this.isAdmin,
  });

  factory JwtUserData.fromJwtJson(Map<String, dynamic> map) {
    List<dynamic> roles = map["realm_access"]["roles"];
    return JwtUserData(
      uuid: map['sub'],
      email: map['email'],
      name: map['name'],
      isAdmin: roles.contains("admin"),
    );
  }
}
