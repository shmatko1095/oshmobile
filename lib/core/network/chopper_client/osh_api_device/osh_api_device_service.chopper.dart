// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'osh_api_device_service.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$ApiDeviceService extends ApiDeviceService {
  _$ApiDeviceService([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = ApiDeviceService;

  @override
  Future<Response<dynamic>> createDevice({required CreateDeviceRequest request}) {
    final Uri $url = Uri.parse('https://api.oshhome.com/v1/devices');
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
  Future<Response<dynamic>> getAll() {
    final Uri $url = Uri.parse('https://api.oshhome.com/v1/devices');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> get({required String id}) {
    final Uri $url = Uri.parse('https://api.oshhome.com/v1/devices/${id}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> delete({required String id}) {
    final Uri $url = Uri.parse('https://api.oshhome.com/v1/devices/${id}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> updateDeviceUserData({
    required String id,
    required UpdateDeviceUserData request,
  }) {
    final Uri $url = Uri.parse('https://api.oshhome.com/v1/devices/${id}/userdata');
    final $body = request;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }
}
