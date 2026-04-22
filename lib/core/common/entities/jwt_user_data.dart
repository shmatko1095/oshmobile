class JwtUserData {
  final String uuid;
  final String email;
  final String name;
  final bool isAdmin;
  final bool isEmailVerified;

  JwtUserData({
    required this.uuid,
    required this.email,
    required this.name,
    required this.isAdmin,
    this.isEmailVerified = true,
  });

  factory JwtUserData.fromJwtJson(Map<String, dynamic> map) {
    final realmAccess = map['realm_access'];
    final rawRoles =
        realmAccess is Map<String, dynamic> ? realmAccess['roles'] : null;
    final roles = rawRoles is List ? rawRoles : const <dynamic>[];

    return JwtUserData(
      uuid: map['sub'],
      email: map['email'],
      name: map['name'],
      isAdmin: roles.contains("admin"),
      isEmailVerified: _parseEmailVerified(map['email_verified']),
    );
  }

  static bool _parseEmailVerified(dynamic rawValue) {
    if (rawValue is bool) {
      return rawValue;
    }
    if (rawValue is String) {
      final normalized = rawValue.trim().toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }

    return true;
  }
}
