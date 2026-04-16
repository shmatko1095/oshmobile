import 'package:chopper/chopper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:oshmobile/core/error/exceptions.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_response_mapper.dart';

void main() {
  test('requireJsonList parses valid JSON list payload', () {
    final response = Response<dynamic>(
      http.Response('', 200),
      <dynamic>[
        <String, dynamic>{'uuid': 'u1', 'email': 'a@example.com'},
        <String, dynamic>{'uuid': 'u2', 'email': 'b@example.com'},
      ],
    );

    final actual = MobileV1ResponseMapper.requireJsonList(response);

    expect(actual, hasLength(2));
    expect(actual.first['uuid'], 'u1');
    expect(actual.last['email'], 'b@example.com');
  });

  test('requireJsonList returns empty list when payload is empty list', () {
    final response = Response<dynamic>(
      http.Response('', 200),
      <dynamic>[],
    );

    final actual = MobileV1ResponseMapper.requireJsonList(response);

    expect(actual, isEmpty);
  });

  test('requireJsonList throws ServerException for non-success response', () {
    final response = Response<dynamic>(
      http.Response('', 500),
      <String, dynamic>{'message': 'boom'},
    );

    expect(
      () => MobileV1ResponseMapper.requireJsonList(response),
      throwsA(isA<ServerException>()),
    );
  });
}
