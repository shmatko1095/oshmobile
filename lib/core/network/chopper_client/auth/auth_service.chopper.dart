// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'auth_service.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$AuthService extends AuthService {
  _$AuthService([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = AuthService;

  @override
  Future<Response<dynamic>> signInWithUserCred({
    required String username,
    required String password,
    String grantType = "password",
    String clientId = AppSecrets.oshClientId,
    String clientSecret = AppSecrets.oshClientSecret,
  }) {
    final Uri $url = Uri.parse('https://auth.oshhome.com/realms/users-dev/protocol/openid-connect/token');
    final Map<String, String> $headers = {
      'content-type': 'application/x-www-form-urlencoded',
    };
    final $body = <String, String>{
      'username': username.toString(),
      'password': password.toString(),
      'grant_type': grantType.toString(),
      'client_id': clientId.toString(),
      'client_secret': clientSecret.toString(),
    };
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      headers: $headers,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> signInWithClientCred({
    String grantType = "client_credentials",
    String clientId = AppSecrets.oshClientId,
    String clientSecret = AppSecrets.oshClientSecret,
  }) {
    final Uri $url = Uri.parse('https://auth.oshhome.com/realms/users-dev/protocol/openid-connect/token');
    final Map<String, String> $headers = {
      'content-type': 'application/x-www-form-urlencoded',
    };
    final $body = <String, String>{
      'grant_type': grantType.toString(),
      'client_id': clientId.toString(),
      'client_secret': clientSecret.toString(),
    };
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      headers: $headers,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> refreshToken({
    required String refreshToken,
    String grantType = "refresh_token",
    String clientId = AppSecrets.oshClientId,
    String clientSecret = AppSecrets.oshClientSecret,
  }) {
    final Uri $url = Uri.parse('https://auth.oshhome.com/realms/users-dev/protocol/openid-connect/token');
    final Map<String, String> $headers = {
      'content-type': 'application/x-www-form-urlencoded',
    };
    final $body = <String, String>{
      'refresh_token': refreshToken.toString(),
      'grant_type': grantType.toString(),
      'client_id': clientId.toString(),
      'client_secret': clientSecret.toString(),
    };
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
