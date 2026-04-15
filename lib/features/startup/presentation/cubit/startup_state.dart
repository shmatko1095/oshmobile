import 'package:flutter/foundation.dart';

enum StartupStage {
  checkingConnectivity,
  restoringSession,
  noInternet,
  ready,
}

@immutable
class StartupState {
  const StartupState({
    this.stage = StartupStage.checkingConnectivity,
    this.isRetrying = false,
  });

  final StartupStage stage;
  final bool isRetrying;

  StartupState copyWith({
    StartupStage? stage,
    bool? isRetrying,
  }) {
    return StartupState(
      stage: stage ?? this.stage,
      isRetrying: isRetrying ?? this.isRetrying,
    );
  }
}
