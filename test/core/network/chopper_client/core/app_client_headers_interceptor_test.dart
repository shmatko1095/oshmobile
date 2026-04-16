import 'package:chopper/chopper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:oshmobile/core/network/app_client/app_client_metadata.dart';
import 'package:oshmobile/core/network/app_client/app_client_metadata_provider.dart';
import 'package:oshmobile/core/network/chopper_client/core/app_client_headers_interceptor.dart';

void main() {
  test('adds X-App headers for OSH API requests', () async {
    final interceptor = AppClientHeadersInterceptor(
      metadataProvider: const _FakeMetadataProvider(
        AppClientMetadata(
          platform: 'android',
          appVersion: '1.0.6',
          build: 14,
        ),
      ),
    );

    final request = Request(
      'GET',
      Uri.parse('https://api.oshhome.com/v1/mobile/me/devices'),
      Uri.parse('https://api.oshhome.com'),
      headers: const {'Accept': 'application/json'},
    );

    final chain = _RecordingChain<dynamic>(request);
    await interceptor.intercept(chain);

    expect(chain.forwardedRequest, isNotNull);
    expect(chain.forwardedRequest!.headers['X-App-Platform'], 'android');
    expect(chain.forwardedRequest!.headers['X-App-Version'], '1.0.6');
    expect(chain.forwardedRequest!.headers['X-App-Build'], '14');
  });

  test('does not add X-App headers for non-OSH requests', () async {
    final interceptor = AppClientHeadersInterceptor(
      metadataProvider: const _FakeMetadataProvider(
        AppClientMetadata(
          platform: 'android',
          appVersion: '1.0.6',
          build: 14,
        ),
      ),
    );

    final request = Request(
      'POST',
      Uri.parse(
          'https://auth.oshhome.com/realms/users-dev/protocol/openid-connect/token'),
      Uri.parse('https://auth.oshhome.com'),
      headers: const {'Content-Type': 'application/x-www-form-urlencoded'},
    );

    final chain = _RecordingChain<dynamic>(request);
    await interceptor.intercept(chain);

    expect(chain.forwardedRequest, isNotNull);
    expect(
        chain.forwardedRequest!.headers.containsKey('X-App-Platform'), isFalse);
    expect(
        chain.forwardedRequest!.headers.containsKey('X-App-Version'), isFalse);
    expect(chain.forwardedRequest!.headers.containsKey('X-App-Build'), isFalse);
  });
}

class _RecordingChain<BodyType> implements Chain<BodyType> {
  _RecordingChain(this.request);

  @override
  final Request request;

  Request? forwardedRequest;

  @override
  Future<Response<BodyType>> proceed(Request request) async {
    forwardedRequest = request;
    return Response<BodyType>(
      http.Response('', 200),
      null,
    );
  }
}

class _FakeMetadataProvider implements AppClientMetadataProvider {
  const _FakeMetadataProvider(this.metadata);

  final AppClientMetadata metadata;

  @override
  Future<AppClientMetadata> getMetadata() async => metadata;
}
