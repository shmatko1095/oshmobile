abstract interface class StartupAuthBootstrapper {
  Future<StartupAuthBootstrapResult> checkAuthStatus();
}

enum StartupAuthBootstrapResult {
  authenticated,
  unauthenticated,
  transientFailure,
}
