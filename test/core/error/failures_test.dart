import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/error/exceptions.dart';
import 'package:oshmobile/core/error/failures.dart';

void main() {
  test('fromServerException preserves raw server error fields', () {
    final failure = Failure.fromServerException(
      ServerException(
        'Token is used or expired',
        code: 'token_used_or_expired',
        details: <String, String>{'request_id': 'req-1'},
      ),
    );

    expect(failure.type, FailureType.unexpected);
    expect(failure.message, 'Token is used or expired');
    expect(failure.code, 'token_used_or_expired');
    expect(failure.details, <String, String>{'request_id': 'req-1'});
  });
}
