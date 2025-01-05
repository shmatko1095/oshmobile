// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'osh_api_user_device_service.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$OshApiUserDeviceService extends OshApiUserDeviceService {
  _$OshApiUserDeviceService([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = OshApiUserDeviceService;

  @override
  Future<Response<dynamic>> assignDevice({
    required String uuid,
    required AssignDeviceRequest request,
  }) {
    final Uri $url = Uri.parse('https://oshhome.com/v1/user/${uuid}/device');
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
    required String uuid,
    required UnassignDeviceRequest request,
  }) {
    final Uri $url = Uri.parse('https://oshhome.com/v1/user/${uuid}/device');
    final $body = request;
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> getDeviceList({required String uuid}) {
    final Uri $url = Uri.parse('https://oshhome.com/v1/user/${uuid}/device');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }
}
