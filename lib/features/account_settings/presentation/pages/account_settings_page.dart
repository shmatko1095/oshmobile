import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/analytics/osh_analytics_screens.dart';
import 'package:oshmobile/core/common/cubits/app/app_theme_cubit.dart';
import 'package:oshmobile/core/common/cubits/auth/global_auth_cubit.dart';
import 'package:oshmobile/core/common/entities/jwt_user_data.dart';
import 'package:oshmobile/core/common/widgets/app_card.dart';
import 'package:oshmobile/core/network/app_client/app_client_metadata_provider.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/features/account_settings/domain/models/app_theme_preference.dart';
import 'package:oshmobile/features/account_settings/domain/usecases/request_my_account_deletion.dart';
import 'package:oshmobile/features/account_settings/presentation/cubit/account_settings_cubit.dart';
import 'package:oshmobile/features/account_settings/presentation/cubit/account_settings_state.dart';
import 'package:oshmobile/features/account_settings/presentation/pages/account_profile_page.dart';
import 'package:oshmobile/features/account_settings/presentation/widgets/account_settings_section.dart';
import 'package:oshmobile/features/startup/domain/repositories/startup_client_policy_repository.dart';
import 'package:oshmobile/features/startup/presentation/widgets/mobile_policy_update_flow.dart';
import 'package:oshmobile/features/startup/presentation/widgets/startup_recommend_update_dialog.dart';
import 'package:oshmobile/generated/l10n.dart';
import 'package:oshmobile/init_dependencies.dart';

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  static MaterialPageRoute<void> route() {
    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: OshAnalyticsScreens.accountSettings),
      builder: (_) => const AccountSettingsPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AccountSettingsCubit>(
      create: (_) => AccountSettingsCubit(
        appThemeCubit: context.read<AppThemeCubit>(),
        requestMyAccountDeletion: locator<RequestMyAccountDeletion>(),
        clientPolicyRepository: locator<StartupClientPolicyRepository>(),
        appClientMetadataProvider: locator<AppClientMetadataProvider>(),
      ),
      child: const _AccountSettingsView(),
    );
  }
}

class _AccountSettingsView extends StatelessWidget {
  const _AccountSettingsView();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final userData = context.select<GlobalAuthCubit, JwtUserData?>((cubit) {
      return cubit.getJwtUserData();
    });
    final isDemoMode =
        context.select<GlobalAuthCubit, bool>((cubit) => cubit.isDemoMode);
    final userName = userData?.name.trim() ?? '';
    final email = userData?.email.trim() ?? '';

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(s.ProfileAndSettings),
      ),
      body: SafeArea(
        child: BlocConsumer<AccountSettingsCubit, AccountSettingsState>(
          listenWhen: (previous, current) {
            return previous.versionCheckOutcomeId !=
                    current.versionCheckOutcomeId &&
                current.pendingVersionCheckOutcome != null;
          },
          listener: (context, state) async {
            await _handleVersionCheckOutcome(context, state);
          },
          builder: (context, state) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: [
                _buildProfileCard(context, userName, email, isDemoMode),
                const SizedBox(height: 12),
                _buildThemeSection(context, state),
                const SizedBox(height: 12),
                _buildAboutAppSection(context, state),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleVersionCheckOutcome(
    BuildContext context,
    AccountSettingsState state,
  ) async {
    final outcome = state.pendingVersionCheckOutcome;
    if (outcome == null) {
      return;
    }

    final cubit = context.read<AccountSettingsCubit>();
    cubit.clearVersionCheckOutcome();

    switch (outcome.type) {
      case AccountSettingsVersionCheckOutcomeType.latestInstalled:
        SnackBarUtils.showSuccess(
          context: context,
          content: S.of(context).LatestVersionInstalled,
        );
      case AccountSettingsVersionCheckOutcomeType.failed:
        SnackBarUtils.showFail(
          context: context,
          content: S.of(context).UnableToCheckForUpdates,
        );
      case AccountSettingsVersionCheckOutcomeType.recommendUpdate:
        final policy = outcome.policy;
        if (policy == null) {
          SnackBarUtils.showFail(
            context: context,
            content: S.of(context).UnableToCheckForUpdates,
          );
          return;
        }

        await showStartupRecommendUpdateDialog(
          context: context,
          onUpdateNow: () async {
            Navigator.of(context, rootNavigator: true).pop();
            await launchMobilePolicyUpdate(
              source: 'settings_manual_check',
              storeUrl: policy.storeUrl,
              status: outcome.status,
              policy: policy,
            );
          },
          onLater: () async {
            Navigator.of(context, rootNavigator: true).pop();
            await cubit.onRecommendUpdateLaterTapped(policy: policy);
          },
        );
      case AccountSettingsVersionCheckOutcomeType.requireUpdate:
        final policy = outcome.policy;
        if (policy == null) {
          SnackBarUtils.showFail(
            context: context,
            content: S.of(context).UnableToCheckForUpdates,
          );
          return;
        }

        await showBlockingStartupForceUpdateFlow(
          context: context,
          onUpdateNow: () {
            unawaited(
              launchMobilePolicyUpdate(
                source: 'settings_manual_check',
                storeUrl: policy.storeUrl,
                status: outcome.status,
                policy: policy,
              ),
            );
          },
        );
    }
  }

  Widget _buildProfileCard(
    BuildContext context,
    String userName,
    String email,
    bool isDemoMode,
  ) {
    final s = S.of(context);
    final safeName = userName.isEmpty ? s.Account : userName;
    final avatarText =
        safeName.isNotEmpty ? safeName.substring(0, 1).toUpperCase() : 'U';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppPalette.surface : AppPalette.white;
    final avatarSurface =
        isDark ? AppPalette.surfaceAlt : AppPalette.lightSurfaceMuted;
    final titleColor =
        isDark ? AppPalette.textPrimary : AppPalette.lightTextStrong;
    final subtitleColor =
        isDark ? AppPalette.textSecondary : AppPalette.lightTextMuted;

    return AppSolidCard(
      onTap: () => _openProfile(context),
      backgroundColor: surface,
      borderColor: isDark ? AppPalette.borderSoft : AppPalette.lightBorder,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: avatarSurface,
            child: Text(
              avatarText,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  safeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: titleColor,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: subtitleColor,
                      ),
                ),
                if (isDemoMode) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppPalette.accentPrimary.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppPalette.radiusPill),
                    ),
                    child: Text(
                      s.DemoMode,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color: titleColor,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppPalette.lightTextDisabled,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSection(
    BuildContext context,
    AccountSettingsState state,
  ) {
    final s = S.of(context);
    final cubit = context.read<AccountSettingsCubit>();

    return AccountSettingsSection(
      title: s.Theme,
      children: [
        _buildThemeTile(
          context,
          title: s.ThemeSystem,
          value: AppThemePreference.system,
          groupValue: state.selectedTheme,
          onSelected: cubit.changeTheme,
          showDivider: true,
        ),
        _buildThemeTile(
          context,
          title: s.ThemeDark,
          value: AppThemePreference.dark,
          groupValue: state.selectedTheme,
          onSelected: cubit.changeTheme,
          showDivider: true,
        ),
        _buildThemeTile(
          context,
          title: s.ThemeLight,
          value: AppThemePreference.light,
          groupValue: state.selectedTheme,
          onSelected: cubit.changeTheme,
          showDivider: false,
        ),
      ],
    );
  }

  Widget _buildAboutAppSection(
    BuildContext context,
    AccountSettingsState state,
  ) {
    final s = S.of(context);
    final cubit = context.read<AccountSettingsCubit>();
    final versionLabel = state.installedVersionLabel.trim().isEmpty
        ? '—'
        : state.installedVersionLabel;

    return AccountSettingsSection(
      title: s.AboutApp,
      children: [
        AccountSettingsActionTile(
          title: s.AppVersion,
          subtitle: versionLabel,
          leading: const Icon(
            Icons.system_update_rounded,
            color: AppPalette.accentPrimary,
          ),
          trailing: state.isCheckingVersion
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(
                  Icons.chevron_right_rounded,
                  color: AppPalette.lightTextDisabled,
                ),
          onTap: state.isCheckingVersion ? null : cubit.checkAppVersion,
        ),
      ],
    );
  }

  Future<void> _openProfile(BuildContext context) async {
    await Navigator.of(context).push(
      AccountProfilePage.route(cubit: context.read<AccountSettingsCubit>()),
    );
  }

  Widget _buildThemeTile(
    BuildContext context, {
    required String title,
    required AppThemePreference value,
    required AppThemePreference groupValue,
    required ValueChanged<AppThemePreference> onSelected,
    required bool showDivider,
  }) {
    final selected = groupValue == value;

    return AccountSettingsActionTile(
      title: title,
      trailing: Icon(
        selected ? Icons.check_circle_rounded : Icons.circle_outlined,
        color:
            selected ? AppPalette.accentPrimary : AppPalette.lightTextDisabled,
      ),
      onTap: () => onSelected(value),
      showDivider: showDivider,
    );
  }
}
