import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/analytics/osh_analytics.dart';
import 'package:oshmobile/core/analytics/osh_analytics_events.dart';
import 'package:oshmobile/core/common/cubits/auth/global_auth_cubit.dart';
import 'package:oshmobile/core/common/entities/jwt_user_data.dart';
import 'package:oshmobile/core/common/widgets/app_card.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/account_settings/presentation/pages/account_settings_page.dart';
import 'package:oshmobile/generated/l10n.dart';

class AccountDrawerHeader extends StatelessWidget {
  const AccountDrawerHeader({super.key});

  void _openAccountSettings(BuildContext context) {
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    Navigator.of(context).pop();
    unawaited(OshAnalytics.logEvent(OshAnalyticsEvents.accountSettingsOpened));
    rootNavigator.push(AccountSettingsPage.route());
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final JwtUserData? userData =
        context.select<GlobalAuthCubit, JwtUserData?>((cubit) {
      return cubit.getJwtUserData();
    });
    final isDemoMode =
        context.select<GlobalAuthCubit, bool>((cubit) => cubit.isDemoMode);
    if (userData == null) {
      return const SizedBox.shrink();
    }

    final name = userData.name.trim();
    final avatarText =
        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppPalette.surface : AppPalette.white;
    final avatarSurface =
        isDark ? AppPalette.surfaceAlt : AppPalette.lightSurfaceMuted;
    final titleColor =
        isDark ? AppPalette.textPrimary : AppPalette.lightTextStrong;
    final subtitleColor =
        isDark ? AppPalette.textSecondary : AppPalette.lightTextMuted;
    final showUnverifiedEmailBadge = !isDemoMode && !userData.isEmailVerified;
    final statusChips = <Widget>[
      if (isDemoMode)
        _buildStatusChip(
          label: s.DemoMode,
          backgroundColor: AppPalette.accentPrimary.withValues(alpha: 0.12),
          textColor: titleColor,
        ),
      if (showUnverifiedEmailBadge)
        _buildStatusChip(
          label: s.VerifyYourEmail,
          backgroundColor:
              AppPalette.accentWarning.withValues(alpha: isDark ? 0.22 : 0.14),
          textColor: isDark ? AppPalette.destructiveFg : AppPalette.accentError,
        ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: AppSolidCard(
        onTap: () => _openAccountSettings(context),
        backgroundColor: surface,
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userData.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userData.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: subtitleColor,
                    ),
                  ),
                  if (statusChips.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: statusChips,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
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
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip({
    required String label,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppPalette.radiusPill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: textColor,
        ),
      ),
    );
  }
}
