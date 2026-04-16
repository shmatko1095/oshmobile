enum MobileClientPolicyStatus {
  allow,
  recommendUpdate,
  requireUpdate,
}

extension MobileClientPolicyStatusMapper on MobileClientPolicyStatus {
  String get wireValue => switch (this) {
        MobileClientPolicyStatus.allow => 'allow',
        MobileClientPolicyStatus.recommendUpdate => 'recommend_update',
        MobileClientPolicyStatus.requireUpdate => 'require_update',
      };

  static MobileClientPolicyStatus? fromWire(String? raw) {
    final normalized = raw?.trim().toLowerCase();
    return switch (normalized) {
      'allow' => MobileClientPolicyStatus.allow,
      'recommend_update' => MobileClientPolicyStatus.recommendUpdate,
      'require_update' => MobileClientPolicyStatus.requireUpdate,
      _ => null,
    };
  }
}
