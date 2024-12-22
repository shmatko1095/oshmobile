// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'osh_api_user_service.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$OshApiUserService extends OshApiUserService {
  _$OshApiUserService([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = OshApiUserService;

  @override
  Future<Response<dynamic>> registerUser({
    required String accessToken,
    required RegisterUserRequest request,
  }) {
    final Uri $url = Uri.parse('https://oshhome.com/v1/user');
    final Map<String, String> $headers = {
      'authorization': accessToken,
    };
    final $body = request;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      headers: $headers,
    );
    return client.send<dynamic, dynamic>($request);
  }
}
