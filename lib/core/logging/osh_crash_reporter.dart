import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Thin wrapper around Firebase Crashlytics with project–specific helpers.
class OshCrashReporter {
  OshCrashReporter._();

  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  /// Enable or disable Crashlytics collection.
  ///
  /// Call this once in `main()` depending on build type (debug / release).
  static Future<void> setCollectionEnabled(bool enabled) {
    return _crashlytics.setCrashlyticsCollectionEnabled(enabled);
  }

  /// Set current user identifier (e.g. UUID or email).
  static Future<void> setUserId(String userId) {
    return _crashlytics.setUserIdentifier(userId);
  }

  /// Set multiple custom keys in a single call.
  ///
  /// Values will be converted to supported types (String / num / bool).
  static Future<void> setContext(Map<String, Object?> context) async {
    for (final entry in context.entries) {
      await _setCustomKeySafe(entry.key, entry.value);
    }
  }

  /// Add a single log line to Crashlytics breadcrumb trail.
  static void log(String message) {
    _crashlytics.log(message);
  }

  /// Report a non-fatal error (app continues to run).
  static Future<void> logNonFatal(
    Object error,
    StackTrace stack, {
    String? reason,
    Map<String, Object?>? context,
  }) async {
    if (context != null) {
      await setContext(context);
    }

    await _crashlytics.recordError(
      error,
      stack,
      fatal: false,
      reason: reason,
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

    await _crashlytics.recordError(
      error,
      stack,
      fatal: true,
      reason: reason,
    );
  }

  /// Helper to safely set custom keys with different value types.
  static Future<void> _setCustomKeySafe(String key, Object? value) async {
    if (value == null) {
      await _crashlytics.setCustomKey(key, 'null');
    } else if (value is bool) {
      await _crashlytics.setCustomKey(key, value);
    } else if (value is num) {
      await _crashlytics.setCustomKey(key, value);
    } else {
      await _crashlytics.setCustomKey(key, value.toString());
    }
  }
}
