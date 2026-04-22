import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/logging/app_log.dart';
import 'package:oshmobile/core/logging/app_logging.dart';

void main() {
  group('AppLog sanitizer', () {
    test('masks bearer token, jwt and secret-like fields', () async {
      final lines = <String>[];

      AppLogging.bootstrap(
        isReleaseMode: false,
        enableVerboseLogs: true,
        sink: lines.add,
      );

      const bearerToken = 'Bearer aVerySensitiveBearerToken123456';
      const jwtToken =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.ZXlKaGJHY2lPaUpJVXpJMU5pSjkuZXlKemRXSWlPaUl4TWpNME5UWTNPRGt3SW4w';

      AppLog.warn('Authorization: $bearerToken');
      AppLog.debug('jwt=$jwtToken');
      AppLog.error(
        'login failed',
        error:
            'client_secret=superSecret password:plainPass refresh_token=rawRefreshToken',
      );

      await Future<void>.delayed(Duration.zero);

      final output = lines.join('\n');
      expect(output, isNot(contains('aVerySensitiveBearerToken123456')));
      expect(output, isNot(contains(jwtToken)));
      expect(output, isNot(contains('superSecret')));
      expect(output, isNot(contains('plainPass')));
      expect(output, isNot(contains('rawRefreshToken')));
      expect(output, contains('***'));
    });
  });
}
