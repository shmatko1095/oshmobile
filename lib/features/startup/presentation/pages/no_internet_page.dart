import 'package:flutter/material.dart';
import 'package:oshmobile/core/common/widgets/app_button.dart';
import 'package:oshmobile/core/common/widgets/app_card.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/generated/l10n.dart';

bool _noInternetIsDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color _noInternetSurfaceColor(BuildContext context) =>
    _noInternetIsDark(context) ? AppPalette.surface : AppPalette.white;

Color _noInternetBorderColor(BuildContext context) =>
    _noInternetIsDark(context) ? AppPalette.borderSoft : AppPalette.lightBorder;

Color _noInternetPrimaryTextColor(BuildContext context) =>
    _noInternetIsDark(context)
        ? AppPalette.textPrimary
        : AppPalette.lightTextPrimary;

Color _noInternetSecondaryTextColor(BuildContext context) =>
    _noInternetIsDark(context)
        ? AppPalette.textSecondary
        : AppPalette.lightTextSecondary;

class NoInternetPage extends StatelessWidget {
  const NoInternetPage({
    super.key,
    required this.onRetry,
    this.isChecking = false,
  });

  final VoidCallback onRetry;
  final bool isChecking;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final s = S.of(context);
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppPalette.spaceXl,
                vertical: AppPalette.spaceLg,
              ),
              child: Semantics(
                liveRegion: true,
                label: s.startupNoInternetScreenSemantics,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 124,
                      height: 124,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppPalette.accentPrimary.withValues(alpha: 0.30),
                            bgColor,
                          ],
                          radius: 0.85,
                        ),
                      ),
                      child: Icon(
                        Icons.wifi_off_rounded,
                        size: 58,
                        color: _noInternetPrimaryTextColor(context),
                      ),
                    ),
                    const SizedBox(height: AppPalette.spaceXl),
                    AppSolidCard(
                      backgroundColor: _noInternetSurfaceColor(context),
                      borderColor: _noInternetBorderColor(context),
                      padding: const EdgeInsets.all(AppPalette.spaceXl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            s.startupNoInternetTitle,
                            textAlign: TextAlign.center,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: _noInternetPrimaryTextColor(context),
                            ),
                          ),
                          const SizedBox(height: AppPalette.spaceSm),
                          Text(
                            s.startupNoInternetSubtitle,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              color: _noInternetSecondaryTextColor(context),
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: AppPalette.spaceLg),
                          _HintRow(
                            icon: Icons.wifi,
                            text: s.startupNoInternetHintNetwork,
                          ),
                          const SizedBox(height: AppPalette.spaceSm),
                          _HintRow(
                            icon: Icons.router,
                            text: s.startupNoInternetHintRetry,
                          ),
                          const SizedBox(height: AppPalette.spaceXl),
                          AppButton(
                            text: s.Retry,
                            onPressed: isChecking ? null : onRetry,
                            isLoading: isChecking,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                          ),
                        ],
                      ),
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

class _HintRow extends StatelessWidget {
  const _HintRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppPalette.accentPrimary),
        const SizedBox(width: AppPalette.spaceSm),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _noInternetSecondaryTextColor(context),
                  height: 1.35,
                ),
          ),
        ),
      ],
    );
  }
}
