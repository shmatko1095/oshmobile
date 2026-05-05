import 'dart:convert';

import 'package:chopper/chopper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oshmobile/core/network/app_client/app_client_metadata_provider.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_service.dart';
import 'package:oshmobile/core/network/rest_response_error_mapper.dart';
import 'package:oshmobile/features/startup/domain/models/mobile_app_version.dart';
import 'package:oshmobile/features/startup/domain/models/mobile_client_policy.dart';
import 'package:oshmobile/features/startup/domain/models/mobile_client_policy_decision.dart';
import 'package:oshmobile/features/startup/domain/models/mobile_client_policy_status.dart';
import 'package:oshmobile/features/startup/domain/repositories/startup_client_policy_repository.dart';

class StartupClientPolicyRepositoryImpl
    implements StartupClientPolicyRepository {
  StartupClientPolicyRepositoryImpl({
    required MobileV1Service mobileService,
    required AppClientMetadataProvider metadataProvider,
    required SharedPreferences sharedPreferences,
  })  : _mobileService = mobileService,
        _metadataProvider = metadataProvider,
        _sharedPreferences = sharedPreferences;

  static const String _cacheKeyPrefix = 'mobile_client_policy.cache.v1.';
  static const String _recommendSuppressionPrefix =
      'mobile_client_policy.recommend_dismissed.v1.';

  final MobileV1Service _mobileService;
  final AppClientMetadataProvider _metadataProvider;
  final SharedPreferences _sharedPreferences;

  @override
  Future<MobileClientPolicyDecision> checkPolicy() async {
    final metadata = await _metadataProvider.getMetadata();

    try {
      final response = await _mobileService.getClientPolicy(
        platform: metadata.platform,
        appVersion: metadata.appVersion,
        build: metadata.build,
      );

      final parsed = _parseResponse(response);
      final policy = parsed.policy;
      await _savePolicyToCache(metadata.platform, policy);

      final status = parsed.remoteStatus ??
          _resolveStatus(
            appVersionRaw: metadata.appVersion,
            minSupportedRaw: policy.minSupportedVersion,
            latestRaw: policy.latestVersion,
          ) ??
          MobileClientPolicyStatus.allow;

      final shouldShowRecommendPrompt =
          status == MobileClientPolicyStatus.recommendUpdate &&
              !await _isRecommendSuppressed(
                platform: metadata.platform,
                policyVersion: policy.policyVersion,
              );

      return MobileClientPolicyDecision(
        status: status,
        policy: policy,
        httpStatus: response.statusCode,
        shouldShowRecommendPrompt: shouldShowRecommendPrompt,
      );
    } on _PolicyHttpException catch (error) {
      final cachedPolicy = _readPolicyFromCache(metadata.platform);
      if (cachedPolicy == null) {
        return MobileClientPolicyDecision(
          status: MobileClientPolicyStatus.allow,
          failOpen: true,
          httpStatus: error.httpStatus,
        );
      }

      final status = _resolveStatus(
            appVersionRaw: metadata.appVersion,
            minSupportedRaw: cachedPolicy.minSupportedVersion,
            latestRaw: cachedPolicy.latestVersion,
          ) ??
          MobileClientPolicyStatus.allow;

      final shouldShowRecommendPrompt =
          status == MobileClientPolicyStatus.recommendUpdate &&
              !await _isRecommendSuppressed(
                platform: metadata.platform,
                policyVersion: cachedPolicy.policyVersion,
              );

      return MobileClientPolicyDecision(
        status: status,
        policy: cachedPolicy,
        fromCache: true,
        httpStatus: error.httpStatus,
        shouldShowRecommendPrompt: shouldShowRecommendPrompt,
      );
    } catch (_) {
      final cachedPolicy = _readPolicyFromCache(metadata.platform);
      if (cachedPolicy == null) {
        return const MobileClientPolicyDecision(
          status: MobileClientPolicyStatus.allow,
          failOpen: true,
        );
      }

      final status = _resolveStatus(
            appVersionRaw: metadata.appVersion,
            minSupportedRaw: cachedPolicy.minSupportedVersion,
            latestRaw: cachedPolicy.latestVersion,
          ) ??
          MobileClientPolicyStatus.allow;

      final shouldShowRecommendPrompt =
          status == MobileClientPolicyStatus.recommendUpdate &&
              !await _isRecommendSuppressed(
                platform: metadata.platform,
                policyVersion: cachedPolicy.policyVersion,
              );

      return MobileClientPolicyDecision(
        status: status,
        policy: cachedPolicy,
        fromCache: true,
        shouldShowRecommendPrompt: shouldShowRecommendPrompt,
      );
    }
  }

  @override
  Future<void> suppressRecommendPrompt({required int policyVersion}) async {
    final metadata = await _metadataProvider.getMetadata();
    final key = _suppressionKey(
      platform: metadata.platform,
      policyVersion: policyVersion,
    );
    await _sharedPreferences.setBool(key, true);
  }

  MobileClientPolicyStatus? _resolveStatus({
    required String appVersionRaw,
    required String minSupportedRaw,
    required String latestRaw,
  }) {
    final appVersion = MobileAppVersion.tryParse(appVersionRaw);
    final minSupported = MobileAppVersion.tryParse(minSupportedRaw);
    final latest = MobileAppVersion.tryParse(latestRaw);

    if (appVersion == null || minSupported == null || latest == null) {
      return null;
    }

    if (appVersion.compareTo(minSupported) < 0) {
      return MobileClientPolicyStatus.requireUpdate;
    }
    if (appVersion.compareTo(latest) < 0) {
      return MobileClientPolicyStatus.recommendUpdate;
    }
    return MobileClientPolicyStatus.allow;
  }

  _ParsedPolicyResponse _parseResponse(Response<dynamic> response) {
    if (!response.isSuccessful) {
      throw _PolicyHttpException(
        response.statusCode,
        RestResponseErrorMapper.messageFromResponse(response),
      );
    }

    final body = _decodeMap(response.body);
    if (body == null) {
      throw const FormatException('Invalid mobile client policy response body');
    }

    final minSupported = body['min_supported_version']?.toString().trim() ?? '';
    final latest = body['latest_version']?.toString().trim() ?? '';
    final storeUrl = body['store_url']?.toString().trim() ?? '';
    if (minSupported.isEmpty || latest.isEmpty || storeUrl.isEmpty) {
      throw const FormatException('Incomplete mobile client policy fields');
    }

    final policyVersion = _asInt(body['policy_version']);
    if (policyVersion == null || policyVersion <= 0) {
      throw const FormatException('Invalid mobile client policy version');
    }

    final checkedAt = _parseTimestamp(body['checked_at']);
    if (checkedAt == null) {
      throw const FormatException('Invalid mobile client policy timestamp');
    }

    final policy = MobileClientPolicy(
      minSupportedVersion: minSupported,
      latestVersion: latest,
      storeUrl: storeUrl,
      policyVersion: policyVersion,
      checkedAt: checkedAt.toUtc(),
      fetchedAt: DateTime.now().toUtc(),
    );

    final remoteStatus = MobileClientPolicyStatusMapper.fromWire(
      body['status']?.toString(),
    );

    return _ParsedPolicyResponse(policy: policy, remoteStatus: remoteStatus);
  }

  Future<void> _savePolicyToCache(String platform, MobileClientPolicy policy) {
    return _sharedPreferences.setString(
      _cacheKey(platform),
      jsonEncode(policy.toJson()),
    );
  }

  MobileClientPolicy? _readPolicyFromCache(String platform) {
    final raw = _sharedPreferences.getString(_cacheKey(platform));
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      final map = _decodeMap(decoded);
      if (map == null) {
        return null;
      }
      return MobileClientPolicy.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<bool> _isRecommendSuppressed({
    required String platform,
    required int policyVersion,
  }) async {
    final key = _suppressionKey(
      platform: platform,
      policyVersion: policyVersion,
    );
    if (!_sharedPreferences.containsKey(key)) {
      return false;
    }

    final raw = _sharedPreferences.get(key);
    if (raw is bool) {
      return raw;
    }
    if (raw is num) {
      return raw != 0;
    }
    if (raw is String) {
      return raw.trim().isNotEmpty;
    }
    return true;
  }

  String _cacheKey(String platform) => '$_cacheKeyPrefix$platform';

  String _suppressionKey({
    required String platform,
    required int policyVersion,
  }) {
    return '$_recommendSuppressionPrefix$platform.$policyVersion';
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final text = value.trim();
      if (text.isEmpty) return null;
      return int.tryParse(text);
    }
    return null;
  }

  DateTime? _parseTimestamp(dynamic raw) {
    if (raw == null) {
      return null;
    }
    if (raw is DateTime) {
      return raw.toUtc();
    }
    if (raw is num) {
      return _epochToUtc(raw);
    }

    final text = raw.toString().trim();
    if (text.isEmpty) {
      return null;
    }

    final parsedIso = DateTime.tryParse(text);
    if (parsedIso != null) {
      return parsedIso.toUtc();
    }

    final parsedNum = num.tryParse(text);
    if (parsedNum != null) {
      return _epochToUtc(parsedNum);
    }
    return null;
  }

  DateTime _epochToUtc(num value) {
    final abs = value.abs();
    if (abs >= 100000000000000) {
      return DateTime.fromMicrosecondsSinceEpoch(value.round(), isUtc: true);
    }
    if (abs >= 100000000000) {
      return DateTime.fromMillisecondsSinceEpoch(value.round(), isUtc: true);
    }
    final micros = (value * 1000000).round();
    return DateTime.fromMicrosecondsSinceEpoch(micros, isUtc: true);
  }

  Map<String, dynamic>? _decodeMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        return _decodeMap(decoded);
      } on FormatException {
        return null;
      }
    }
    return null;
  }
}

class _ParsedPolicyResponse {
  const _ParsedPolicyResponse({
    required this.policy,
    required this.remoteStatus,
  });

  final MobileClientPolicy policy;
  final MobileClientPolicyStatus? remoteStatus;
}

class _PolicyHttpException implements Exception {
  const _PolicyHttpException(this.httpStatus, this.message);

  final int httpStatus;
  final String message;
}
