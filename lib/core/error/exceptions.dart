class ServerException implements Exception {
  final String message;

  ServerException(this.message);
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
