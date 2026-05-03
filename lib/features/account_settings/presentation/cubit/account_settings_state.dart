import 'package:flutter/foundation.dart';
import 'package:oshmobile/features/account_settings/domain/models/app_theme_preference.dart';
import 'package:oshmobile/features/startup/domain/models/mobile_client_policy.dart';
import 'package:oshmobile/features/startup/domain/models/mobile_client_policy_status.dart';

enum AccountSettingsVersionCheckOutcomeType {
  latestInstalled,
  failed,
  recommendUpdate,
  requireUpdate,
}

@immutable
class AccountSettingsVersionCheckOutcome {
  const AccountSettingsVersionCheckOutcome._({
    required this.type,
    this.policy,
    this.status,
  });

  const AccountSettingsVersionCheckOutcome.latestInstalled()
      : this._(type: AccountSettingsVersionCheckOutcomeType.latestInstalled);

  const AccountSettingsVersionCheckOutcome.failed()
      : this._(type: AccountSettingsVersionCheckOutcomeType.failed);

  const AccountSettingsVersionCheckOutcome.recommendUpdate({
    required MobileClientPolicy policy,
    required MobileClientPolicyStatus status,
  }) : this._(
          type: AccountSettingsVersionCheckOutcomeType.recommendUpdate,
          policy: policy,
          status: status,
        );

  const AccountSettingsVersionCheckOutcome.requireUpdate({
    required MobileClientPolicy policy,
    required MobileClientPolicyStatus status,
  }) : this._(
          type: AccountSettingsVersionCheckOutcomeType.requireUpdate,
          policy: policy,
          status: status,
        );

  final AccountSettingsVersionCheckOutcomeType type;
  final MobileClientPolicy? policy;
  final MobileClientPolicyStatus? status;
}

@immutable
class AccountSettingsState {
  final AppThemePreference selectedTheme;
  final bool isDeleting;
  final bool isCheckingVersion;
  final String installedVersionLabel;
  final AccountSettingsVersionCheckOutcome? pendingVersionCheckOutcome;
  final int versionCheckOutcomeId;

  const AccountSettingsState({
    this.selectedTheme = AppThemePreference.system,
    this.isDeleting = false,
    this.isCheckingVersion = false,
    this.installedVersionLabel = '',
    this.pendingVersionCheckOutcome,
    this.versionCheckOutcomeId = 0,
  });

  AccountSettingsState copyWith({
    AppThemePreference? selectedTheme,
    bool? isDeleting,
    bool? isCheckingVersion,
    String? installedVersionLabel,
    AccountSettingsVersionCheckOutcome? pendingVersionCheckOutcome,
    int? versionCheckOutcomeId,
    bool clearPendingVersionCheckOutcome = false,
  }) {
    return AccountSettingsState(
      selectedTheme: selectedTheme ?? this.selectedTheme,
      isDeleting: isDeleting ?? this.isDeleting,
      isCheckingVersion: isCheckingVersion ?? this.isCheckingVersion,
      installedVersionLabel:
          installedVersionLabel ?? this.installedVersionLabel,
      pendingVersionCheckOutcome: clearPendingVersionCheckOutcome
          ? null
          : (pendingVersionCheckOutcome ?? this.pendingVersionCheckOutcome),
      versionCheckOutcomeId:
          versionCheckOutcomeId ?? this.versionCheckOutcomeId,
    );
  }
}
