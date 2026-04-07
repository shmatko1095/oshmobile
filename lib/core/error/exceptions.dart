class ServerException implements Exception {
  final String message;
  final String? code;

  ServerException(this.message, {this.code});

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
