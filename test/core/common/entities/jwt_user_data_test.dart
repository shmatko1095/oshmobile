import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/common/entities/jwt_user_data.dart';

void main() {
  group('JwtUserData.fromJwtJson', () {
    test('parses email_verified=true', () {
      final userData = JwtUserData.fromJwtJson(_jwt(emailVerified: true));

      expect(userData.isEmailVerified, isTrue);
    });

    test('parses email_verified=false', () {
      final userData = JwtUserData.fromJwtJson(_jwt(emailVerified: false));

      expect(userData.isEmailVerified, isFalse);
    });

    test('falls back to verified when email_verified claim is missing', () {
      final userData = JwtUserData.fromJwtJson(_jwt());

      expect(userData.isEmailVerified, isTrue);
    });
  });
}

Map<String, dynamic> _jwt({Object? emailVerified = _claimMissing}) {
  final map = <String, dynamic>{
    'sub': 'user-1',
    'email': 'user@example.com',
    'name': 'User Name',
    'realm_access': <String, dynamic>{
      'roles': <String>['user'],
    },
  };

  if (!identical(emailVerified, _claimMissing)) {
    map['email_verified'] = emailVerified;
  }

  return map;
}

const Object _claimMissing = Object();
