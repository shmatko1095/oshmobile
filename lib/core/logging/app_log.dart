import 'package:logging/logging.dart';
import 'package:oshmobile/core/logging/log_sanitizer.dart';

class AppLog {
  AppLog._();

  static final Logger _logger = Logger('app');

  static void debug(String message) {
    _logger.fine(LogSanitizer.sanitize(message));
  }

  static void warn(String message) {
    _logger.warning(LogSanitizer.sanitize(message));
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.severe(
      LogSanitizer.sanitize(message),
      error == null ? null : LogSanitizer.sanitize(error.toString()),
      stackTrace,
    );
  }
}
