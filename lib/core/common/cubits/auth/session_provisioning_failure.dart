enum SessionProvisioningFailureKind {
  authRejected,
  transient,
}

class SessionProvisioningException implements Exception {
  const SessionProvisioningException({
    required this.kind,
    required this.message,
  });

  final SessionProvisioningFailureKind kind;
  final String message;

  bool get isTransient => kind == SessionProvisioningFailureKind.transient;

  @override
  String toString() => message;
}
