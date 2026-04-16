import 'package:flutter/material.dart';
import 'package:oshmobile/core/common/widgets/app_button.dart';
import 'package:oshmobile/core/common/widgets/app_card.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/generated/l10n.dart';

bool _updateGateIsDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color _updateGateSurfaceColor(BuildContext context) =>
    _updateGateIsDark(context) ? AppPalette.surface : AppPalette.white;

Color _updateGateBorderColor(BuildContext context) =>
    _updateGateIsDark(context) ? AppPalette.borderSoft : AppPalette.lightBorder;

Color _updateGatePrimaryTextColor(BuildContext context) =>
    _updateGateIsDark(context)
        ? AppPalette.textPrimary
        : AppPalette.lightTextPrimary;

Color _updateGateSecondaryTextColor(BuildContext context) =>
    _updateGateIsDark(context)
        ? AppPalette.textSecondary
        : AppPalette.lightTextSecondary;

class StartupForceUpdatePage extends StatelessWidget {
  const StartupForceUpdatePage({
    super.key,
    required this.onUpdateNow,
  });

  final VoidCallback onUpdateNow;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(AppPalette.spaceXl),
              child: Semantics(
                liveRegion: true,
                label: s.startupUpdateRequiredSemantics,
                child: AppSolidCard(
                  backgroundColor: _updateGateSurfaceColor(context),
                  borderColor: _updateGateBorderColor(context),
                  padding: const EdgeInsets.all(AppPalette.spaceXl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppPalette.accentPrimary
                                  .withValues(alpha: 0.16),
                              borderRadius:
                                  BorderRadius.circular(AppPalette.radiusLg),
                              border: Border.all(
                                color: AppPalette.accentPrimary
                                    .withValues(alpha: 0.30),
                              ),
                            ),
                            child: const Icon(
                              Icons.system_update_alt_rounded,
                              color: AppPalette.accentPrimary,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: AppPalette.spaceLg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.startupUpdateRequiredTitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: _updateGatePrimaryTextColor(
                                            context),
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: AppPalette.spaceSm),
                                Text(
                                  s.startupUpdateRequiredSubtitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: _updateGateSecondaryTextColor(
                                            context),
                                        height: 1.4,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppPalette.spaceXl),
                      AppButton(
                        text: s.startupUpdateNow,
                        onPressed: onUpdateNow,
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
