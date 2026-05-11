import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:oshmobile/core/logging/app_log.dart';
import 'package:oshmobile/core/logging/log_sanitizer.dart';

abstract class CrashReporterBackend {
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    required bool fatal,
    String? reason,
  });

  Future<void> recordFlutterFatalError(FlutterErrorDetails details);

  Future<void> setCollectionEnabled(bool enabled);

  Future<void> setUserId(String userId);

  Future<void> setCustomKey(String key, Object value);

  void log(String message);
}

final class FirebaseCrashReporterBackend implements CrashReporterBackend {
  FirebaseCrashReporterBackend([FirebaseCrashlytics? crashlytics])
      : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    required bool fatal,
    String? reason,
  }) {
    return _crashlytics.recordError(
      error,
      stack,
      fatal: fatal,
      reason: reason,
    );
  }

  @override
  Future<void> recordFlutterFatalError(FlutterErrorDetails details) {
    return _crashlytics.recordFlutterFatalError(details);
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) {
    return _crashlytics.setCrashlyticsCollectionEnabled(enabled);
  }

  @override
  Future<void> setUserId(String userId) {
    return _crashlytics.setUserIdentifier(userId);
  }

  @override
  Future<void> setCustomKey(String key, Object value) {
    return _crashlytics.setCustomKey(key, value);
  }

  @override
  void log(String message) {
    _crashlytics.log(message);
  }
}

/// Thin wrapper around Firebase Crashlytics with project–specific helpers.
class OshCrashReporter {
  OshCrashReporter._();

  static CrashReporterBackend? _backend;

  static CrashReporterBackend get _currentBackend {
    return _backend ??= FirebaseCrashReporterBackend();
  }

  @visibleForTesting
  static void debugSetBackend(CrashReporterBackend backend) {
    _backend = backend;
  }

  @visibleForTesting
  static void debugResetBackend() {
    _backend = null;
  }

  /// Enable or disable Crashlytics collection.
  ///
  /// Call this once in `main()` depending on build type (debug / release).
  static Future<void> setCollectionEnabled(bool enabled) {
    return _runSafely(
      () => _currentBackend.setCollectionEnabled(enabled),
      operationName: 'setCrashlyticsCollectionEnabled',
    );
  }

  /// Set current user identifier.
  static Future<void> setUserId(String userId) {
    final sanitizedUserId = LogSanitizer.sanitize(userId);
    return _runSafely(
      () => _currentBackend.setUserId(sanitizedUserId),
      operationName: 'setUserIdentifier',
    );
  }

  /// Clear current user identifier in Crashlytics scope.
  static Future<void> clearUserId() {
    return _runSafely(
      () => _currentBackend.setUserId(''),
      operationName: 'clearUserIdentifier',
    );
  }

  /// Set multiple custom keys in a single call.
  ///
  /// Values will be converted to supported types (String / num / bool).
  static Future<void> setContext(Map<String, Object?> context) async {
    for (final entry in context.entries) {
      final normalizedValue = _normalizeContextValue(entry.value);
      await _runSafely(
        () => _setCustomKeySafe(entry.key, normalizedValue),
        operationName: 'setCustomKey(${entry.key})',
      );
    }
  }

  /// Reset selected custom keys in Crashlytics scope.
  static Future<void> clearContext(Iterable<String> keys) async {
    for (final key in keys) {
      await _runSafely(
        () => _setCustomKeySafe(key, 'null'),
        operationName: 'clearCustomKey($key)',
      );
    }
  }

  /// Add a single log line to Crashlytics breadcrumb trail.
  static void log(String message) {
    try {
      _currentBackend.log(LogSanitizer.sanitize(message));
    } catch (error, stack) {
      _reportSdkFailure('log', error, stack);
    }
  }

  /// Report a Flutter framework fatal error without letting Crashlytics failures
  /// crash the app a second time.
  static Future<void> logFlutterFatalError(FlutterErrorDetails details) {
    return _runSafely(
      () => _currentBackend.recordFlutterFatalError(details),
      operationName: 'recordFlutterFatalError',
    );
  }

  /// Report a non-fatal error (app continues to run).
  static Future<void> logNonFatal(
    Object error,
    StackTrace? stack, {
    String? reason,
    Map<String, Object?>? context,
  }) async {
    if (context != null) {
      await setContext(context);
    }

    final sanitizedReason =
        reason == null ? null : LogSanitizer.sanitize(reason);

    await _runSafely(
      () => _currentBackend.recordError(
        error,
        stack,
        fatal: false,
        reason: sanitizedReason,
      ),
      operationName: 'recordError(non-fatal)',
    );
  }

  /// Report a fatal error (usually followed by app crash).
  ///
  /// You normally do not need this directly – use it only if you
  /// intentionally want to mark an error as fatal.
  static Future<void> logFatal(
    Object error,
    StackTrace stack, {
    String? reason,
    Map<String, Object?>? context,
  }) async {
    if (context != null) {
      await setContext(context);
    }

    final sanitizedReason =
        reason == null ? null : LogSanitizer.sanitize(reason);

    await _runSafely(
      () => _currentBackend.recordError(
        error,
        stack,
        fatal: true,
        reason: sanitizedReason,
      ),
      operationName: 'recordError(fatal)',
    );
  }

  /// Helper to safely set custom keys with different value types.
  static Future<void> _setCustomKeySafe(String key, Object value) async {
    if (value is bool) {
      await _currentBackend.setCustomKey(key, value);
    } else if (value is num) {
      await _currentBackend.setCustomKey(key, value);
    } else {
      await _currentBackend.setCustomKey(key, value.toString());
    }
  }

  static Object _normalizeContextValue(Object? value) {
    if (value == null) return 'null';
    if (value is bool || value is num) return value;
    return LogSanitizer.sanitize(value.toString());
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
      'Crashlytics operation failed ($operation)',
      error: error,
      stackTrace: stack,
    );
  }
}
