import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/analytics/osh_analytics_screens.dart';
import 'package:oshmobile/core/common/cubits/auth/global_auth_cubit.dart';
import 'package:oshmobile/core/common/entities/jwt_user_data.dart';
import 'package:oshmobile/core/common/widgets/app_button.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/account_settings/presentation/cubit/account_settings_cubit.dart';
import 'package:oshmobile/features/account_settings/presentation/cubit/account_settings_state.dart';
import 'package:oshmobile/features/account_settings/presentation/pages/account_deletion_request_page.dart';
import 'package:oshmobile/features/account_settings/presentation/widgets/account_settings_section.dart';
import 'package:oshmobile/features/auth/presentation/widgets/verify_email_dialog.dart';
import 'package:oshmobile/generated/l10n.dart';

class AccountProfilePage extends StatelessWidget {
  const AccountProfilePage({super.key});

  static MaterialPageRoute<void> route({
    required AccountSettingsCubit cubit,
  }) {
    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: OshAnalyticsScreens.accountProfile),
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const AccountProfilePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final userData = context.select<GlobalAuthCubit, JwtUserData?>((cubit) {
      return cubit.getJwtUserData();
    });
    final isDemoMode =
        context.select<GlobalAuthCubit, bool>((cubit) => cubit.isDemoMode);
    final safeName = userData?.name.trim().isNotEmpty == true
        ? userData!.name.trim()
        : s.Account;
    final safeEmail = userData?.email.trim() ?? '';
    final avatarText =
        safeName.isNotEmpty ? safeName.substring(0, 1).toUpperCase() : 'U';
    final isEmailVerified = userData?.isEmailVerified ?? true;
    final showVerificationStatus = !isDemoMode;
    final showVerifyCta = showVerificationStatus && !isEmailVerified;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(s.Profile),
      ),
      body: SafeArea(
        child: BlocBuilder<AccountSettingsCubit, AccountSettingsState>(
          builder: (context, state) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
              children: [
                _buildHero(
                  context,
                  avatarText: avatarText,
                  name: safeName,
                  email: safeEmail,
                  isDemoMode: isDemoMode,
                  isEmailVerified: isEmailVerified,
                  showVerificationStatus: showVerificationStatus,
                  showVerifyCta: showVerifyCta,
                ),
                const SizedBox(height: 10),
                AccountSettingsSection(
                  title: s.Account,
                  children: [
                    AccountSettingsActionTile(
                      title: s.DeleteAccount,
                      subtitle: s.DeleteAccountDescription,
                      leading: const Icon(
                        Icons.delete_forever_rounded,
                        color: AppPalette.destructiveFg,
                      ),
                      titleColor: AppPalette.destructiveFg,
                      trailing: state.isDeleting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.chevron_right_rounded,
                              color: AppPalette.lightTextDisabled,
                            ),
                      onTap: state.isDeleting || safeEmail.isEmpty
                          ? null
                          : () => _openDeleteAccount(context, safeEmail),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHero(
    BuildContext context, {
    required String avatarText,
    required String name,
    required String email,
    required bool isDemoMode,
    required bool isEmailVerified,
    required bool showVerificationStatus,
    required bool showVerifyCta,
  }) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        isDark ? AppPalette.textPrimary : AppPalette.lightTextStrong;
    final subtitleColor =
        isDark ? AppPalette.textSecondary : AppPalette.lightTextSecondary;
    final avatarSurface =
        isDark ? AppPalette.surfaceAlt : AppPalette.lightSurfaceMuted;
    final heroMinHeight = MediaQuery.sizeOf(context).height * 0.50;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: heroMinHeight),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: avatarSurface,
              child: Text(
                avatarText,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 36,
                    fontWeight: FontWeight.w500,
                    height: 1.08,
                    letterSpacing: -0.3,
                    color: titleColor,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              email,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: subtitleColor,
                  ),
            ),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (isDemoMode)
                  _StatusBadge(
                    label: s.DemoMode,
                    backgroundColor:
                        AppPalette.accentPrimary.withValues(alpha: 0.12),
                    textColor: titleColor,
                  ),
                if (showVerificationStatus)
                  _StatusBadge(
                    label:
                        isEmailVerified ? s.VerifiedEmail : s.UnverifiedEmail,
                    backgroundColor: isEmailVerified
                        ? AppPalette.accentSuccess.withValues(
                            alpha: isDark ? 0.22 : 0.14,
                          )
                        : AppPalette.accentWarning.withValues(
                            alpha: isDark ? 0.22 : 0.14,
                          ),
                    textColor: isEmailVerified
                        ? (isDark
                            ? AppPalette.accentSuccess
                            : AppPalette.accentSuccess)
                        : (isDark
                            ? AppPalette.destructiveFg
                            : AppPalette.accentError),
                  ),
              ],
            ),
            if (showVerifyCta) ...[
              const SizedBox(height: 22),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: AppButton(
                  text: s.VerifyYourEmail,
                  onPressed: email.isEmpty
                      ? null
                      : () => showVerifyEmailDialog(
                            context: context,
                            email: email,
                          ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openDeleteAccount(BuildContext context, String email) async {
    await Navigator.of(context).push(
      AccountDeletionRequestPage.route(
        cubit: context.read<AccountSettingsCubit>(),
        email: email,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppPalette.radiusPill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
      ),
    );
  }
}
