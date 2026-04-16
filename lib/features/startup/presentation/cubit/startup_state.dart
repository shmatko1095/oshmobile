import 'package:flutter/foundation.dart';
import 'package:oshmobile/features/startup/domain/models/mobile_client_policy.dart';
import 'package:oshmobile/features/startup/domain/models/mobile_client_policy_status.dart';

enum StartupStage {
  checkingConnectivity,
  checkingPolicy,
  restoringSession,
  noInternet,
  ready,
}

@immutable
class StartupState {
  const StartupState({
    this.stage = StartupStage.checkingConnectivity,
    this.isRetrying = false,
    this.isPolicyCheckInProgress = false,
    this.hardUpdateRequired = false,
    this.pendingRecommendPrompt = false,
    this.recommendPromptRequestId = 0,
    this.policy,
    this.policyStatus,
  });

  final StartupStage stage;
  final bool isRetrying;
  final bool isPolicyCheckInProgress;
  final bool hardUpdateRequired;
  final bool pendingRecommendPrompt;
  final int recommendPromptRequestId;
  final MobileClientPolicy? policy;
  final MobileClientPolicyStatus? policyStatus;

  StartupState copyWith({
    StartupStage? stage,
    bool? isRetrying,
    bool? isPolicyCheckInProgress,
    bool? hardUpdateRequired,
    bool? pendingRecommendPrompt,
    int? recommendPromptRequestId,
    MobileClientPolicy? policy,
    MobileClientPolicyStatus? policyStatus,
    bool clearPolicy = false,
    bool clearPolicyStatus = false,
  }) {
    return StartupState(
      stage: stage ?? this.stage,
      isRetrying: isRetrying ?? this.isRetrying,
      isPolicyCheckInProgress:
          isPolicyCheckInProgress ?? this.isPolicyCheckInProgress,
      hardUpdateRequired: hardUpdateRequired ?? this.hardUpdateRequired,
      pendingRecommendPrompt:
          pendingRecommendPrompt ?? this.pendingRecommendPrompt,
      recommendPromptRequestId:
          recommendPromptRequestId ?? this.recommendPromptRequestId,
      policy: clearPolicy ? null : (policy ?? this.policy),
      policyStatus:
          clearPolicyStatus ? null : (policyStatus ?? this.policyStatus),
    );
  }
}
