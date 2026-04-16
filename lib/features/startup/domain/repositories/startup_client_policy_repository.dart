import 'package:oshmobile/features/startup/domain/models/mobile_client_policy_decision.dart';

abstract interface class StartupClientPolicyRepository {
  Future<MobileClientPolicyDecision> checkPolicy();

  Future<void> suppressRecommendPrompt({required int policyVersion});
}
