// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'osh_api_user_service.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$ApiUserService extends ApiUserService {
  _$ApiUserService([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = ApiUserService;

  @override
  Future<Response<dynamic>> get({required String userId}) {
    final Uri $url = Uri.parse('https://api.oshhome.com/v1/users/${userId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> getDevices({required String userId}) {
    final Uri $url = Uri.parse('https://api.oshhome.com/v1/users/${userId}/devices');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

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
    final Uri $url = Uri.parse('https://api.oshhome.com/v1/users/reset-password');
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
  Future<Response<dynamic>> delete({required String userId}) {
    final Uri $url = Uri.parse('https://api.oshhome.com/v1/users/${userId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> assignDevice({
    required String userId,
    required String deviceSn,
    required AssignDeviceRequest request,
  }) {
    final Uri $url = Uri.parse('https://api.oshhome.com/v1/users/${userId}/device/${deviceSn}');
    final $body = request;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> unassignDevice({
    required String userId,
    required String deviceId,
  }) {
    final Uri $url = Uri.parse('https://api.oshhome.com/v1/users/${userId}/device/${deviceId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }
}
