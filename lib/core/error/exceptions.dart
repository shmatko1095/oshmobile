class ServerException implements Exception {
  final String message;
  final String? code;
  final Map<String, String> details;

  ServerException(
    this.message, {
    this.code,
    Map<String, String>? details,
  }) : details = Map.unmodifiable(details ?? const <String, String>{});

  @override
  String toString() => message;
}

class ConflictException implements Exception {
  const ConflictException();
}

class EmailNotVerifiedException implements Exception {
  const EmailNotVerifiedException();
}

class InvalidUserCredentialsException implements Exception {
  const InvalidUserCredentialsException();
}
