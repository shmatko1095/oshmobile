import 'package:chopper/chopper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oshmobile/core/network/app_client/app_client_metadata.dart';
import 'package:oshmobile/core/network/app_client/app_client_metadata_provider.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_service.dart';
import 'package:oshmobile/features/startup/data/repositories/startup_client_policy_repository_impl.dart';
import 'package:oshmobile/features/startup/domain/models/mobile_client_policy_status.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('returns online decision and caches policy', () async {
    final prefs = await SharedPreferences.getInstance();
    final mobileService = _FakeMobileV1Service()
      ..onGetClientPolicy = ({
        required String platform,
        required String appVersion,
        int? build,
      }) async {
        return _response(
          statusCode: 200,
          body: {
            'status': 'recommend_update',
            'min_supported_version': '1.0.0',
            'latest_version': '3.0.0',
            'store_url': 'https://example.com/store',
            'checked_at': 1776373941.144289985,
            'policy_version': 5,
          },
        );
      };

    final repository = StartupClientPolicyRepositoryImpl(
      mobileService: mobileService,
      metadataProvider: const _FakeMetadataProvider(
        AppClientMetadata(
          platform: 'android',
          appVersion: '2.0.0',
          build: 14,
        ),
      ),
      sharedPreferences: prefs,
    );

    final decision = await repository.checkPolicy();

    expect(decision.status, MobileClientPolicyStatus.recommendUpdate);
    expect(decision.fromCache, isFalse);
    expect(decision.failOpen, isFalse);
    expect(decision.policy?.policyVersion, 5);
    expect(decision.policy?.checkedAt.isUtc, isTrue);
    expect(decision.shouldShowRecommendPrompt, isTrue);
  });

  test('falls back to cached policy when request fails', () async {
    final prefs = await SharedPreferences.getInstance();
    final mobileService = _FakeMobileV1Service()
      ..onGetClientPolicy = ({
        required String platform,
        required String appVersion,
        int? build,
      }) async {
        return _response(
          statusCode: 200,
          body: {
            'status': 'recommend_update',
            'min_supported_version': '1.0.0',
            'latest_version': '3.0.0',
            'store_url': 'https://example.com/store',
            'checked_at': 1776373941.144289985,
            'policy_version': 7,
          },
        );
      };

    final repository = StartupClientPolicyRepositoryImpl(
      mobileService: mobileService,
      metadataProvider: const _FakeMetadataProvider(
        AppClientMetadata(
          platform: 'android',
          appVersion: '2.0.0',
          build: 14,
        ),
      ),
      sharedPreferences: prefs,
    );

    await repository.checkPolicy();

    mobileService.onGetClientPolicy = ({
      required String platform,
      required String appVersion,
      int? build,
    }) async {
      return _response(statusCode: 500, body: {'message': 'boom'});
    };

    final fallback = await repository.checkPolicy();

    expect(fallback.fromCache, isTrue);
    expect(fallback.failOpen, isFalse);
    expect(fallback.status, MobileClientPolicyStatus.recommendUpdate);
    expect(fallback.policy?.policyVersion, 7);
    expect(fallback.httpStatus, 500);
  });

  test('fail-open when request fails and cache is missing', () async {
    final prefs = await SharedPreferences.getInstance();
    final mobileService = _FakeMobileV1Service()
      ..onGetClientPolicy = ({
        required String platform,
        required String appVersion,
        int? build,
      }) async {
        return _response(statusCode: 503, body: {'message': 'unavailable'});
      };

    final repository = StartupClientPolicyRepositoryImpl(
      mobileService: mobileService,
      metadataProvider: const _FakeMetadataProvider(
        AppClientMetadata(
          platform: 'android',
          appVersion: '2.0.0',
          build: 14,
        ),
      ),
      sharedPreferences: prefs,
    );

    final decision = await repository.checkPolicy();

    expect(decision.status, MobileClientPolicyStatus.allow);
    expect(decision.failOpen, isTrue);
    expect(decision.fromCache, isFalse);
    expect(decision.policy, isNull);
    expect(decision.httpStatus, 503);
  });

  test(
      'recommend prompt is suppressed for current policy version only after later tap',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final mobileService = _FakeMobileV1Service()
      ..onGetClientPolicy = ({
        required String platform,
        required String appVersion,
        int? build,
      }) async {
        return _response(
          statusCode: 200,
          body: {
            'status': 'recommend_update',
            'min_supported_version': '1.0.0',
            'latest_version': '3.0.0',
            'store_url': 'https://example.com/store',
            'checked_at': 1776373941.144289985,
            'policy_version': 9,
          },
        );
      };

    final repository = StartupClientPolicyRepositoryImpl(
      mobileService: mobileService,
      metadataProvider: const _FakeMetadataProvider(
        AppClientMetadata(
          platform: 'android',
          appVersion: '2.0.0',
          build: 14,
        ),
      ),
      sharedPreferences: prefs,
    );

    final first = await repository.checkPolicy();
    expect(first.shouldShowRecommendPrompt, isTrue);

    await repository.suppressRecommendPrompt(policyVersion: 9);

    final second = await repository.checkPolicy();
    expect(second.shouldShowRecommendPrompt, isFalse);

    mobileService.onGetClientPolicy = ({
      required String platform,
      required String appVersion,
      int? build,
    }) async {
      return _response(
        statusCode: 200,
        body: {
          'status': 'recommend_update',
          'min_supported_version': '1.0.0',
          'latest_version': '3.0.0',
          'store_url': 'https://example.com/store',
          'checked_at': 1776374941.144289985,
          'policy_version': 10,
        },
      );
    };

    final third = await repository.checkPolicy();
    expect(third.shouldShowRecommendPrompt, isTrue);
  });
}

Response<dynamic> _response({
  required int statusCode,
  required dynamic body,
}) {
  return Response<dynamic>(http.Response('', statusCode), body);
}

class _FakeMetadataProvider implements AppClientMetadataProvider {
  const _FakeMetadataProvider(this.metadata);

  final AppClientMetadata metadata;

  @override
  Future<AppClientMetadata> getMetadata() async => metadata;
}

class _FakeMobileV1Service extends MobileV1Service {
  Future<Response<dynamic>> Function({
    required String platform,
    required String appVersion,
    int? build,
  })? onGetClientPolicy;

  @override
  Future<Response> getClientPolicy({
    required String platform,
    required String appVersion,
    int? build,
  }) {
    return onGetClientPolicy!(
      platform: platform,
      appVersion: appVersion,
      build: build,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
