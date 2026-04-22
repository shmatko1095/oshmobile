class LogSanitizer {
  LogSanitizer._();

  static final RegExp _bearerTokenPattern = RegExp(
    r'(bearer\s+)[A-Za-z0-9\-._~+/]+=*',
    caseSensitive: false,
  );
  static final RegExp _secretFieldPattern = RegExp(
    r'''(access[_-]?token|refresh[_-]?token|client[_-]?secret|password)(["']?\s*[:=]\s*["']?)([^"'\s,}]+)''',
    caseSensitive: false,
  );
  static final RegExp _jwtPattern = RegExp(
    r'\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b',
  );

  static String sanitize(String value) {
    var sanitized = value;
    sanitized = sanitized.replaceAllMapped(
      _bearerTokenPattern,
      (match) => '${match.group(1)}***',
    );
    sanitized = sanitized.replaceAllMapped(
      _secretFieldPattern,
      (match) => '${match.group(1)}${match.group(2)}***',
    );
    sanitized = sanitized.replaceAll(_jwtPattern, '***');
    return sanitized;
  }
}
