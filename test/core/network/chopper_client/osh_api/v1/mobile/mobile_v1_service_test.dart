import 'dart:async';

import 'package:chopper/chopper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_service.dart';

void main() {
  test('ensureMySession posts to session endpoint', () async {
    final capture = _CaptureInterceptor();
    final client = ChopperClient(
      baseUrl: Uri.parse('https://api.oshhome.com'),
      services: [MobileV1Service.create()],
      interceptors: [capture],
    );
    final service = client.getService<MobileV1Service>();

    await service.ensureMySession();

    expect(capture.request, isNotNull);
    expect(capture.request!.method, 'POST');
    expect(capture.request!.url.path, '/v1/mobile/me/session');
  });

  test('getMyDeviceTelemetryAggregate uses aggregate endpoint', () async {
    final capture = _CaptureInterceptor();
    final client = ChopperClient(
      baseUrl: Uri.parse('https://api.oshhome.com'),
      services: [MobileV1Service.create()],
      interceptors: [capture],
    );
    final service = client.getService<MobileV1Service>();

    await service.getMyDeviceTelemetryAggregate(
      serial: 'SN-1',
      seriesKeys: 'power_meter.energy_wh_delta',
      from: '2026-03-13T10:00:00Z',
      to: '2026-03-14T10:00:00Z',
    );

    expect(capture.request, isNotNull);
    expect(capture.request!.method, 'GET');
    expect(
      capture.request!.url.path,
      '/v1/mobile/devices/SN-1/telemetry/aggregate',
    );
    expect(
      capture.request!.parameters['series_keys'],
      'power_meter.energy_wh_delta',
    );
    expect(capture.request!.parameters['resolution'], 'auto');
  });
}

class _CaptureInterceptor implements Interceptor {
  final List<Request> requests = <Request>[];

  Request? get request => requests.isEmpty ? null : requests.last;

  @override
  FutureOr<Response<BodyType>> intercept<BodyType>(Chain<BodyType> chain) {
    requests.add(chain.request);
    return Response<BodyType>(http.Response('', 204), null);
  }
}
