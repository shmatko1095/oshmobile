import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:oshmobile/core/analytics/osh_analytics_user_properties.dart';
import 'package:oshmobile/core/logging/app_log.dart';

abstract class AnalyticsBackend {
  Future<void> setCollectionEnabled(bool enabled);

  Future<void> setUserId(String? userId);

  Future<void> setUserProperty({
    required String name,
    required String? value,
  });

  Future<void> logEvent(
    String name, {
    Map<String, Object?>? parameters,
  });

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
    Map<String, Object?>? parameters,
  });
}

final class FirebaseAnalyticsBackend implements AnalyticsBackend {
  FirebaseAnalyticsBackend([FirebaseAnalytics? analytics])
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  @override
  Future<void> setCollectionEnabled(bool enabled) {
    return _analytics.setAnalyticsCollectionEnabled(enabled);
  }

  @override
  Future<void> setUserId(String? userId) {
    return _analytics.setUserId(id: userId);
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) {
    return _analytics.setUserProperty(name: name, value: value);
  }

  @override
  Future<void> logEvent(
    String name, {
    Map<String, Object?>? parameters,
  }) {
    return _analytics.logEvent(
      name: name,
      parameters: OshAnalytics.normalizeParameters(parameters),
    );
  }

  @override
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
    Map<String, Object?>? parameters,
  }) {
    return _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
      parameters: OshAnalytics.normalizeParameters(parameters),
    );
  }
}

class OshAnalytics {
  OshAnalytics._();

  static AnalyticsBackend? _backend;

  static AnalyticsBackend get _currentBackend {
    return _backend ??= FirebaseAnalyticsBackend();
  }

  @visibleForTesting
  static void debugSetBackend(AnalyticsBackend backend) {
    _backend = backend;
  }

  @visibleForTesting
  static void debugResetBackend() {
    _backend = null;
  }

  static Future<void> setCollectionEnabled(bool enabled) {
    return _runSafely(
      () => _currentBackend.setCollectionEnabled(enabled),
      operationName: 'setAnalyticsCollectionEnabled',
    );
  }

  static Future<void> setUserId(String? userId) {
    return _runSafely(
      () => _currentBackend.setUserId(userId),
      operationName: 'setUserId',
    );
  }

  static Future<void> setUserProperty({
    required String name,
    required String? value,
  }) {
    return _runSafely(
      () => _currentBackend.setUserProperty(name: name, value: value),
      operationName: 'setUserProperty($name)',
    );
  }

  static Future<void> resetSessionContext() async {
    await setUserId(null);
    await setUserProperty(
      name: OshAnalyticsUserProperties.sessionMode,
      value: null,
    );
    await setUserProperty(
      name: OshAnalyticsUserProperties.authProvider,
      value: null,
    );
  }

  static Future<void> logEvent(
    String name, {
    Map<String, Object?>? parameters,
  }) {
    final normalized = normalizeParameters(parameters);
    return _runSafely(
      () => _currentBackend.logEvent(name, parameters: normalized),
      operationName: 'logEvent($name)',
    );
  }

  static Future<void> logScreenView({
    required String screenName,
    String? screenClass,
    Map<String, Object?>? parameters,
  }) {
    final normalized = normalizeParameters(parameters);
    return _runSafely(
      () => _currentBackend.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
        parameters: normalized,
      ),
      operationName: 'logScreenView($screenName)',
    );
  }

  static Map<String, Object>? normalizeParameters(
    Map<String, Object?>? parameters,
  ) {
    if (parameters == null || parameters.isEmpty) {
      return null;
    }

    final normalized = <String, Object>{};
    for (final entry in parameters.entries) {
      final value = _normalizeValue(entry.value);
      if (value != null) {
        normalized[entry.key] = value;
      }
    }

    return normalized.isEmpty ? null : normalized;
  }

  static Object? _normalizeValue(Object? value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (value is bool) {
      return value ? 1 : 0;
    }
    if (value is int || value is double) {
      return value;
    }
    if (value is num) {
      final asDouble = value.toDouble();
      return asDouble == asDouble.roundToDouble() ? asDouble.round() : asDouble;
    }
    return value.toString();
  }

  static Future<void> _runSafely(
    Future<void> Function() operation, {
    required String operationName,
  }) async {
    try {
      await operation();
    } catch (error, stack) {
      _reportSdkFailure(operationName, error, stack);
    }
  }

  static void _reportSdkFailure(
    String operation,
    Object error,
    StackTrace stack,
  ) {
    AppLog.error(
      'Analytics operation failed ($operation)',
      error: error,
      stackTrace: stack,
    );
  }
}
