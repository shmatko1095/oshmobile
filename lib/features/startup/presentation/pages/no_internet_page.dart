import 'package:flutter/material.dart';
import 'package:oshmobile/core/common/widgets/app_button.dart';
import 'package:oshmobile/core/common/widgets/app_card.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/generated/l10n.dart';

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

    return Scaffold(
      backgroundColor: AppPalette.canvas,
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
                            AppPalette.canvas,
                          ],
                          radius: 0.85,
                        ),
                      ),
                      child: const Icon(
                        Icons.wifi_off_rounded,
                        size: 58,
                        color: AppPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppPalette.spaceXl),
                    AppSolidCard(
                      backgroundColor: AppPalette.surface,
                      borderColor: AppPalette.borderSoft,
                      padding: const EdgeInsets.all(AppPalette.spaceXl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            s.startupNoInternetTitle,
                            textAlign: TextAlign.center,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppPalette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppPalette.spaceSm),
                          Text(
                            s.startupNoInternetSubtitle,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppPalette.textSecondary,
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
                  color: AppPalette.textSecondary,
                  height: 1.35,
                ),
          ),
        ),
      ],
    );
  }
}
