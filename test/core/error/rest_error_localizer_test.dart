import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/presentation/errors/rest_error_localizer.dart';
import 'package:oshmobile/generated/l10n.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await S.load(const Locale('en'));
  });

  test('resolve returns localized text for known backend code', () {
    final message = RestErrorLocalizer.resolve(
      code: 'validation_error',
      fallback: 'Request validation failed',
    );

    expect(message, S.current.ApiValidationError);
  });

  test('resolve falls back to backend message for unknown backend code', () {
    final message = RestErrorLocalizer.resolve(
      code: 'future_backend_code',
      fallback: 'Fallback from backend',
    );

    expect(message, 'Fallback from backend');
  });
}
