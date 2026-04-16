// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'mobile_v1_service.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$MobileV1Service extends MobileV1Service {
  _$MobileV1Service([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = MobileV1Service;

  @override
  Future<Response<dynamic>> listMyDevices() {
    final Uri $url = Uri.parse('https://api.oshhome.com/v1/mobile/me/devices');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> createDemoSession() {
    final Uri $url =
        Uri.parse('https://api.oshhome.com/v1/mobile/demo/session');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> getMyDevice({required String serial}) {
    final Uri $url =
        Uri.parse('https://api.oshhome.com/v1/mobile/devices/${serial}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> getMyDeviceUsers({required String serial}) {
    final Uri $url =
        Uri.parse('https://api.oshhome.com/v1/mobile/devices/${serial}/users');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> claimMyDevice({
    required String serial,
    required ClaimMyDeviceRequest request,
  }) {
    final Uri $url =
        Uri.parse('https://api.oshhome.com/v1/mobile/devices/${serial}/claim');
    final $body = request;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> unassignMyDevice({required String serial}) {
    final Uri $url =
        Uri.parse('https://api.oshhome.com/v1/mobile/devices/${serial}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> updateMyDeviceUserData({
    required String serial,
    required UpdateMyDeviceUserDataRequest request,
  }) {
    final Uri $url = Uri.parse(
        'https://api.oshhome.com/v1/mobile/devices/${serial}/userdata');
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
  Future<Response<dynamic>> requestMyAccountDeletion() {
    final Uri $url =
        Uri.parse('https://api.oshhome.com/v1/mobile/me/account-deletion');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> getMyDeviceTelemetryHistory({
    required String serial,
    required String seriesKeys,
    required String from,
    required String to,
    String resolution = 'auto',
  }) {
    final Uri $url = Uri.parse(
        'https://api.oshhome.com/v1/mobile/devices/${serial}/telemetry/history');
    final Map<String, dynamic> $params = <String, dynamic>{
      'series_keys': seriesKeys,
      'from': from,
      'to': to,
      'resolution': resolution,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<dynamic, dynamic>($request);
  }
}
