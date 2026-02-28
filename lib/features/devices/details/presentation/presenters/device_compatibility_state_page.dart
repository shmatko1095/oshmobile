import 'package:flutter/material.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/common/widgets/app_button.dart';
import 'package:oshmobile/core/common/widgets/app_card.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/core/theme/text_styles.dart';
import 'package:oshmobile/generated/l10n.dart';

enum DeviceCompatibilityVariant {
  updateRequired,
  compatibilityError,
}

class DeviceCompatibilityStatePage extends StatelessWidget {
  final Device device;
  final DeviceCompatibilityVariant variant;
  final String details;
  final VoidCallback onRetry;

  const DeviceCompatibilityStatePage({
    super.key,
    required this.device,
    required this.variant,
    required this.details,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final spec = _spec(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(AppPalette.spaceLg),
              children: [
                AppSolidCard(
                  padding: const EdgeInsets.all(AppPalette.spaceXl),
                  backgroundColor: AppPalette.surface,
                  borderColor: AppPalette.borderSoft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatusBadge(
                        label: spec.badge,
                        color: spec.accentColor,
                      ),
                      const SizedBox(height: AppPalette.spaceLg),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeroIcon(
                            icon: spec.icon,
                            color: spec.accentColor,
                          ),
                          const SizedBox(width: AppPalette.spaceLg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  spec.title,
                                  style: TextStyles.titleStyle.copyWith(
                                    fontSize: 28,
                                    color: AppPalette.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: AppPalette.spaceMd),
                                Text(
                                  spec.subtitle,
                                  style: TextStyles.contentStyle,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppPalette.spaceXl),
                      AppButton(
                        text: s.Retry,
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppPalette.spaceLg),
                AppSolidCard(
                  backgroundColor: AppPalette.surfaceRaised,
                  borderColor: AppPalette.borderSoft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.compatibilityNextStepsTitle,
                        style: TextStyles.sectionTitle,
                      ),
                      const SizedBox(height: AppPalette.spaceMd),
                      for (var i = 0; i < spec.steps.length; i++) ...[
                        _StepRow(
                          index: i + 1,
                          text: spec.steps[i],
                          accentColor: spec.accentColor,
                        ),
                        if (i < spec.steps.length - 1)
                          const SizedBox(height: AppPalette.spaceMd),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppPalette.spaceLg),
                AppSolidCard(
                  backgroundColor: AppPalette.surfaceRaised,
                  borderColor: AppPalette.borderSoft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.DeviceDetails,
                        style: TextStyles.sectionTitle,
                      ),
                      const SizedBox(height: AppPalette.spaceMd),
                      _MetaRow(
                        label: s.Name,
                        value: _displayName(device),
                      ),
                      const SizedBox(height: AppPalette.spaceSm),
                      _MetaRow(
                        label: s.SerialNumber,
                        value: device.sn,
                      ),
                      const SizedBox(height: AppPalette.spaceSm),
                      _MetaRow(
                        label: 'Model ID',
                        value: device.modelId,
                      ),
                      const SizedBox(height: AppPalette.spaceSm),
                      _MetaRow(
                        label: 'Device ID',
                        value: device.id,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppPalette.spaceLg),
                AppSolidCard(
                  backgroundColor: AppPalette.surfaceRaised,
                  borderColor: AppPalette.borderSoft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.compatibilityTechnicalDetailsTitle,
                        style: TextStyles.sectionTitle,
                      ),
                      const SizedBox(height: AppPalette.spaceMd),
                      Text(
                        details.trim().isEmpty ? s.UnknownError : details,
                        style: TextStyles.caption.copyWith(
                          color: AppPalette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _CompatibilitySpec _spec(BuildContext context) {
    final s = S.of(context);
    switch (variant) {
      case DeviceCompatibilityVariant.updateRequired:
        return _CompatibilitySpec(
          badge: s.updateAppRequiredBadge,
          title: s.updateAppRequiredTitle,
          subtitle: s.updateAppRequiredSubtitle,
          steps: [
            s.updateAppRequiredStepUpdate,
            s.updateAppRequiredStepReopen,
            s.updateAppRequiredStepContactSupport,
          ],
          accentColor: AppPalette.accentPrimary,
          icon: Icons.system_update_alt_rounded,
        );
      case DeviceCompatibilityVariant.compatibilityError:
        return _CompatibilitySpec(
          badge: s.compatibilityErrorBadge,
          title: s.compatibilityErrorTitle,
          subtitle: s.compatibilityErrorSubtitle,
          steps: [
            s.compatibilityErrorStepCheckConnection,
            s.compatibilityErrorStepRetry,
            s.compatibilityErrorStepContactSupport,
          ],
          accentColor: AppPalette.accentError,
          icon: Icons.error_outline_rounded,
        );
    }
  }

  String _displayName(Device device) {
    final alias = device.userData.alias.trim();
    if (alias.isNotEmpty) return alias;
    final sn = device.sn.trim();
    if (sn.isNotEmpty) return sn;
    return device.id;
  }
}

class _CompatibilitySpec {
  final String badge;
  final String title;
  final String subtitle;
  final List<String> steps;
  final Color accentColor;
  final IconData icon;

  const _CompatibilitySpec({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.steps,
    required this.accentColor,
    required this.icon,
  });
}

class _HeroIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _HeroIcon({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppPalette.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Icon(
        icon,
        size: 32,
        color: color,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppPalette.spaceMd,
        vertical: AppPalette.spaceSm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppPalette.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: TextStyles.caption.copyWith(color: color),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int index;
  final String text;
  final Color accentColor;

  const _StepRow({
    required this.index,
    required this.text,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppPalette.radiusPill),
          ),
          child: Text(
            '$index',
            style: TextStyles.caption.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppPalette.spaceMd),
        Expanded(
          child: Text(
            text,
            style: TextStyles.body,
          ),
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: TextStyles.caption,
          ),
        ),
        const SizedBox(width: AppPalette.spaceMd),
        Expanded(
          child: Text(
            value.trim().isEmpty ? '—' : value,
            style: TextStyles.bodyStrong,
          ),
        ),
      ],
    );
  }
}
