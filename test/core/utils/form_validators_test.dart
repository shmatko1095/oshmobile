import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/utils/form_validators.dart';

void main() {
  const error = 'invalid';

  test('accepts email with dot in local part', () {
    final result = FormValidator.email(
      value: 'oshhome.test1@gmail.com',
      errorMessage: error,
    );

    expect(result, isNull);
  });

  test('accepts plus and subdomain email', () {
    final result = FormValidator.email(
      value: 'name+tag@mail.example.com',
      errorMessage: error,
    );

    expect(result, isNull);
  });

  test('accepts email with extra spaces around it', () {
    final result = FormValidator.email(
      value: '  user.name@gmail.com  ',
      errorMessage: error,
    );

    expect(result, isNull);
  });

  test('rejects email without domain dot', () {
    final result = FormValidator.email(
      value: 'user@gmail',
      errorMessage: error,
    );

    expect(result, error);
  });
}
