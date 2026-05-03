import 'package:flutter/material.dart';
import 'package:oshmobile/core/common/widgets/app_card.dart';
import 'package:oshmobile/core/theme/app_palette.dart';

class AccountSettingsSection extends StatelessWidget {
  const AccountSettingsSection({
    required this.children,
    super.key,
    this.title,
  });

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppSolidCard(
      backgroundColor: isDark ? AppPalette.surface : AppPalette.white,
      borderColor: isDark ? AppPalette.borderSoft : AppPalette.lightBorder,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && title!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Text(
                title!,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
              ),
            ),
          ...children,
        ],
      ),
    );
  }
}

class AccountSettingsActionTile extends StatelessWidget {
  const AccountSettingsActionTile({
    required this.title,
    super.key,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showDivider = false,
    this.titleColor,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedSubtitleColor =
        isDark ? AppPalette.textSecondary : AppPalette.lightTextMuted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: titleColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: resolvedSubtitleColor,
                                    height: 1.35,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                trailing ??
                    (onTap == null
                        ? const SizedBox.shrink()
                        : const Icon(
                            Icons.chevron_right_rounded,
                            color: AppPalette.lightTextDisabled,
                          )),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 0.8,
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}
