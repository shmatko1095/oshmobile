import 'package:flutter/material.dart';
import 'package:oshmobile/core/analytics/osh_analytics_screen_view.dart';
import 'package:oshmobile/core/common/widgets/app_button.dart';
import 'package:oshmobile/core/common/widgets/app_card.dart';
import 'package:oshmobile/core/analytics/osh_analytics_screens.dart';
import 'package:oshmobile/core/theme/app_palette.dart';

bool _noDeviceIsDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

class NoSelectedDevicePage extends StatelessWidget {
  const NoSelectedDevicePage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onActionPressed,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onActionPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = _noDeviceIsDark(context);
    return OshAnalyticsScreenView(
      screenName: OshAnalyticsScreens.homeNoDevice,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: AppSolidCard(
              radius: AppPalette.radiusXl,
              backgroundColor:
                  isDark ? AppPalette.surfaceRaised : AppPalette.white,
              borderColor: isDark
                  ? AppPalette.accentPrimary.withValues(alpha: 0.22)
                  : AppPalette.accentPrimary.withValues(alpha: 0.14),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppPalette.accentPrimary.withValues(
                          alpha: isDark ? 0.18 : 0.12,
                        ),
                      ),
                      child: Icon(
                        Icons.devices_other_rounded,
                        size: 40,
                        color: isDark
                            ? AppPalette.textPrimary
                            : AppPalette.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppPalette.textSecondary
                            : AppPalette.lightTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.45,
                        color: isDark
                            ? AppPalette.textMuted
                            : AppPalette.lightTextSubtle,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      text: actionLabel,
                      onPressed: onActionPressed,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
