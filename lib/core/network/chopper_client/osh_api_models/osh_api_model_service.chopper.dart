// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'osh_api_model_service.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$ApiModelService extends ApiModelService {
  _$ApiModelService([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = ApiModelService;

  @override
  Future<Response<dynamic>> createModel({required CreateModelRequest request}) {
    final Uri $url = Uri.parse('https://api.oshhome.com/v1/models');
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
    final Uri $url = Uri.parse('https://api.oshhome.com/v1/models');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> get({required String id}) {
    final Uri $url = Uri.parse('https://api.oshhome.com/v1/models/${id}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> delete({required String id}) {
    final Uri $url = Uri.parse('https://api.oshhome.com/v1/models/${id}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }
}
