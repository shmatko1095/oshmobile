import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/common/entities/session.dart';
import 'package:oshmobile/core/common/entities/session_mode.dart';

void main() {
  test('parses demo session payload without refresh token', () {
    final session = Session.fromJson(const {
      'access_token': 'demo-token',
      'token_type': 'Bearer',
      'expires_in': 3600,
      'mode': 'demo',
    });

    expect(session.mode, SessionMode.demo);
    expect(session.isDemoMode, isTrue);
    expect(session.refreshToken, isEmpty);
    expect(session.refreshTokenExpiry, isNull);
    expect(session.typedAccessToken, 'Bearer demo-token');
  });
}
