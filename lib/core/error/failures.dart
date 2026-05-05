import 'package:oshmobile/core/error/exceptions.dart';

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
  final String? code;
  final Map<String, String> details;

  const Failure({
    required this.type,
    this.message,
    this.code,
    this.details = const <String, String>{},
  });

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

  static Failure unexpected(
    String message, {
    String? code,
    Map<String, String> details = const <String, String>{},
  }) {
    return Failure(
      type: FailureType.unexpected,
      message: message,
      code: code,
      details: details,
    );
  }

  static Failure fromServerException(ServerException exception) {
    return Failure.unexpected(
      exception.message,
      code: exception.code,
      details: exception.details,
    );
  }
}
