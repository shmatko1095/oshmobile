// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'osh_api_user_auth_service.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$OshApiUserAuthService extends OshApiUserAuthService {
  _$OshApiUserAuthService([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = OshApiUserAuthService;

  @override
  Future<Response<dynamic>> registerUser({
    required String accessToken,
    required RegisterUserRequest request,
  }) {
    final Uri $url = Uri.parse('https://api.oshhome.com/v1/users');
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

  @override
  Future<Response<dynamic>> sendVerificationEmail({
    required String accessToken,
    required SendVerificationEmailRequest request,
  }) {
    final Uri $url = Uri.parse('https://api.oshhome.com/v1/users/verify-email');
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

  @override
  Future<Response<dynamic>> sendResetPasswordEmail({
    required String accessToken,
    required SendResetPasswordEmailRequest request,
  }) {
    final Uri $url =
        Uri.parse('https://api.oshhome.com/v1/users/reset-password');
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
