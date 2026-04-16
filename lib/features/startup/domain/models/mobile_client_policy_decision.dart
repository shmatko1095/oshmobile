import 'package:oshmobile/features/startup/domain/models/mobile_client_policy.dart';
import 'package:oshmobile/features/startup/domain/models/mobile_client_policy_status.dart';

class MobileClientPolicyDecision {
  const MobileClientPolicyDecision({
    required this.status,
    this.policy,
    this.fromCache = false,
    this.failOpen = false,
    this.httpStatus,
    this.shouldShowRecommendPrompt = false,
  });

  final MobileClientPolicyStatus status;
  final MobileClientPolicy? policy;
  final bool fromCache;
  final bool failOpen;
  final int? httpStatus;
  final bool shouldShowRecommendPrompt;

  String? get storeUrl => policy?.storeUrl;
}
