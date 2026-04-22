import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:oshmobile/core/logging/log_sanitizer.dart';

const _enableVerboseLogs =
    bool.fromEnvironment('ENABLE_VERBOSE_LOGS', defaultValue: false);

typedef AppLogSink = void Function(String line);

class AppLogging {
  AppLogging._();

  static StreamSubscription<LogRecord>? _subscription;
  static AppLogSink _sink = _defaultSink;

  static void bootstrap({
    bool? isReleaseMode,
    bool? enableVerboseLogs,
    AppLogSink? sink,
  }) {
    final releaseMode = isReleaseMode ?? kReleaseMode;
    final verbose = enableVerboseLogs ?? _enableVerboseLogs;

    Logger.root.level = _resolveRootLevel(
      isReleaseMode: releaseMode,
      enableVerboseLogs: verbose,
    );

    if (_subscription != null) {
      unawaited(_subscription!.cancel());
      _subscription = null;
    }

    _sink = sink ?? _defaultSink;
    _subscription = Logger.root.onRecord.listen((record) {
      _sink(_formatRecord(record));
    });
  }

  static Level _resolveRootLevel({
    required bool isReleaseMode,
    required bool enableVerboseLogs,
  }) {
    if (isReleaseMode && !enableVerboseLogs) {
      return Level.SEVERE;
    }
    return Level.ALL;
  }

  static String _formatRecord(LogRecord record) {
    final t = record.time.toLocal();
    final ts = '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}:'
        '${t.second.toString().padLeft(2, '0')}.'
        '${t.millisecond.toString().padLeft(3, '0')}';

    final message = LogSanitizer.sanitize(record.message);
    final error = record.error == null
        ? ''
        : ' | error=${LogSanitizer.sanitize(record.error.toString())}';

    return '[$ts] ${record.level.name} ${record.loggerName}: $message$error';
  }

  static void _defaultSink(String line) {
    debugPrint(line);
  }
}
