import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/analytics/osh_analytics.dart';
import 'package:oshmobile/core/analytics/osh_analytics_events.dart';
import 'package:oshmobile/core/common/cubits/app/app_theme_cubit.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';
import 'package:oshmobile/core/network/app_client/app_client_metadata.dart';
import 'package:oshmobile/core/network/app_client/app_client_metadata_provider.dart';
import 'package:oshmobile/core/presentation/errors/rest_error_localizer.dart';
import 'package:oshmobile/core/usecase/usecase.dart';
import 'package:oshmobile/features/account_settings/domain/models/app_theme_preference.dart';
import 'package:oshmobile/features/account_settings/domain/usecases/request_my_account_deletion.dart';
import 'package:oshmobile/features/account_settings/presentation/cubit/account_settings_state.dart';
import 'package:oshmobile/features/startup/domain/models/mobile_client_policy.dart';
import 'package:oshmobile/features/startup/domain/models/mobile_client_policy_decision.dart';
import 'package:oshmobile/features/startup/domain/models/mobile_client_policy_status.dart';
import 'package:oshmobile/features/startup/domain/repositories/startup_client_policy_repository.dart';

class AccountSettingsCubit extends Cubit<AccountSettingsState> {
  AccountSettingsCubit({
    required AppThemeCubit appThemeCubit,
    required RequestMyAccountDeletion requestMyAccountDeletion,
    required StartupClientPolicyRepository clientPolicyRepository,
    required AppClientMetadataProvider appClientMetadataProvider,
  })  : _appThemeCubit = appThemeCubit,
        _requestMyAccountDeletion = requestMyAccountDeletion,
        _clientPolicyRepository = clientPolicyRepository,
        _appClientMetadataProvider = appClientMetadataProvider,
        super(AccountSettingsState(
          selectedTheme: _fromThemeMode(appThemeCubit.state),
        )) {
    _themeSub = _appThemeCubit.stream.listen((mode) {
      final mapped = _fromThemeMode(mode);
      if (mapped == state.selectedTheme) return;
      emit(state.copyWith(selectedTheme: mapped));
    });

    unawaited(_loadInstalledVersion());
  }

  final AppThemeCubit _appThemeCubit;
  final RequestMyAccountDeletion _requestMyAccountDeletion;
  final StartupClientPolicyRepository _clientPolicyRepository;
  final AppClientMetadataProvider _appClientMetadataProvider;
  late final StreamSubscription<ThemeMode> _themeSub;

  void changeTheme(AppThemePreference preference) {
    emit(state.copyWith(selectedTheme: preference));
    unawaited(
      OshAnalytics.logEvent(
        OshAnalyticsEvents.themeChanged,
        parameters: {'theme': preference.name},
      ),
    );
    onThemeChanged(preference);
  }

  Future<void> deleteAccount() async {
    if (state.isDeleting) return;

    emit(state.copyWith(isDeleting: true));
    try {
      await onDeleteAccountConfirmed();
    } catch (error, st) {
      OshCrashReporter.logNonFatal(
        error,
        st,
        reason: 'Account deletion request failed',
      );
      rethrow;
    } finally {
      emit(state.copyWith(isDeleting: false));
    }
  }

  Future<void> checkAppVersion() async {
    if (state.isCheckingVersion) {
      return;
    }

    emit(state.copyWith(
      isCheckingVersion: true,
      clearPendingVersionCheckOutcome: true,
    ));

    try {
      final decision = await _clientPolicyRepository.checkPolicy();
      if (decision.failOpen) {
        _emitVersionCheckOutcome(
          const AccountSettingsVersionCheckOutcome.failed(),
        );
        return;
      }

      switch (decision.status) {
        case MobileClientPolicyStatus.allow:
          _emitVersionCheckOutcome(
            const AccountSettingsVersionCheckOutcome.latestInstalled(),
          );
        case MobileClientPolicyStatus.recommendUpdate:
          final policy = _requireUpdatePolicyOrNull(decision);
          if (policy == null) {
            _emitVersionCheckOutcome(
              const AccountSettingsVersionCheckOutcome.failed(),
            );
            return;
          }
          _emitVersionCheckOutcome(
            AccountSettingsVersionCheckOutcome.recommendUpdate(
              policy: policy,
              status: decision.status,
            ),
          );
        case MobileClientPolicyStatus.requireUpdate:
          final policy = _requireUpdatePolicyOrNull(decision);
          if (policy == null) {
            _emitVersionCheckOutcome(
              const AccountSettingsVersionCheckOutcome.failed(),
            );
            return;
          }
          _emitVersionCheckOutcome(
            AccountSettingsVersionCheckOutcome.requireUpdate(
              policy: policy,
              status: decision.status,
            ),
          );
      }
    } catch (error, st) {
      await OshCrashReporter.logNonFatal(
        error,
        st,
        reason: 'Manual app version check failed',
      );
      _emitVersionCheckOutcome(
        const AccountSettingsVersionCheckOutcome.failed(),
      );
    }
  }

  Future<void> onRecommendUpdateLaterTapped({
    required MobileClientPolicy policy,
  }) async {
    try {
      await _clientPolicyRepository.suppressRecommendPrompt(
        policyVersion: policy.policyVersion,
      );
      await OshAnalytics.logEvent(
        OshAnalyticsEvents.mobilePolicyLaterTapped,
        parameters: {
          'policy_version': policy.policyVersion,
        },
      );
    } catch (error, st) {
      await OshCrashReporter.logNonFatal(
        error,
        st,
        reason: 'Unable to suppress recommended update prompt',
      );
    }
  }

  void clearVersionCheckOutcome() {
    if (state.pendingVersionCheckOutcome == null) {
      return;
    }

    emit(state.copyWith(clearPendingVersionCheckOutcome: true));
  }

  void onThemeChanged(AppThemePreference preference) {
    _appThemeCubit.setThemeMode(_toThemeMode(preference));
  }

  Future<void> onDeleteAccountConfirmed() async {
    final result = await _requestMyAccountDeletion(NoParams());
    await result.fold(
      (failure) => throw StateError(
        RestErrorLocalizer.resolveFailure(
          failure,
          fallback: 'Account deletion request failed',
        ),
      ),
      (_) => OshAnalytics.logEvent(OshAnalyticsEvents.accountDeletionRequested),
    );
  }

  @override
  Future<void> close() async {
    await _themeSub.cancel();
    return super.close();
  }

  void _emitVersionCheckOutcome(AccountSettingsVersionCheckOutcome outcome) {
    emit(state.copyWith(
      isCheckingVersion: false,
      pendingVersionCheckOutcome: outcome,
      versionCheckOutcomeId: state.versionCheckOutcomeId + 1,
    ));
  }

  MobileClientPolicy? _requireUpdatePolicyOrNull(
    MobileClientPolicyDecision decision,
  ) {
    final policy = decision.policy;
    if (policy == null || policy.storeUrl.trim().isEmpty) {
      return null;
    }
    return policy;
  }

  Future<void> _loadInstalledVersion() async {
    try {
      final metadata = await _appClientMetadataProvider.getMetadata();
      emit(state.copyWith(
        installedVersionLabel: _formatInstalledVersion(metadata),
      ));
    } catch (error, st) {
      await OshCrashReporter.logNonFatal(
        error,
        st,
        reason: 'Unable to load installed app version',
      );
    }
  }

  static AppThemePreference _fromThemeMode(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => AppThemePreference.system,
      ThemeMode.dark => AppThemePreference.dark,
      ThemeMode.light => AppThemePreference.light,
    };
  }

  static String _formatInstalledVersion(AppClientMetadata metadata) {
    final version = metadata.appVersion.trim();
    final build = metadata.build;

    if (version.isEmpty && build == null) {
      return '';
    }
    if (build == null) {
      return version;
    }
    if (version.isEmpty) {
      return build.toString();
    }
    return '$version ($build)';
  }

  static ThemeMode _toThemeMode(AppThemePreference preference) {
    return switch (preference) {
      AppThemePreference.system => ThemeMode.system,
      AppThemePreference.dark => ThemeMode.dark,
      AppThemePreference.light => ThemeMode.light,
    };
  }
}
