enum FailureType {
  conflict,
  emailNotVerified,
  invalidUserCredentials,
  noInternetConnection,
  unexpected,
}

class Failure {
  final FailureType type;
  final String? message;

  const Failure({required this.type, this.message});

  static Failure emailNotVerified() {
    return const Failure(type: FailureType.emailNotVerified);
  }

  static Failure invalidUserCredentials() {
    return const Failure(type: FailureType.invalidUserCredentials);
  }

  static Failure conflict() {
    return const Failure(type: FailureType.conflict);
  }

  static Failure noInternetConnection() {
    return const Failure(type: FailureType.noInternetConnection);
  }

  static Failure unexpected(String message) {
    return Failure(type: FailureType.unexpected, message: message);
  }
}
