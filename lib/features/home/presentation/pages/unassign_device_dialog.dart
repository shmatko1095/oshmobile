import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/generated/l10n.dart';

class UnassignDeviceDialog extends StatelessWidget {
  const UnassignDeviceDialog({
    super.key,
    required this.deviceName,
  });

  final String deviceName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppPalette.surfaceRaised : AppPalette.white;
    final borderColor =
        isDark ? AppPalette.borderSoft : AppPalette.lightBorderSubtle;
    final titleStyle = theme.textTheme.titleLarge?.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onSurface,
    );
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
      color: isDark ? AppPalette.textSecondary : AppPalette.lightTextSecondary,
      height: 1.45,
    );
    final deviceNameStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface,
      height: 1.45,
    );

    return Dialog(
      backgroundColor: AppPalette.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Material(
          key: const ValueKey('unassign_device_dialog_surface'),
          color: surfaceColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppPalette.radiusXl),
            side: BorderSide(color: borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppPalette.spaceXl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DestructiveBadge(isDark: isDark),
                const SizedBox(height: AppPalette.spaceLg),
                Text(
                  S.of(context).RemoveDeviceConfirmTitle,
                  style: titleStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppPalette.spaceMd),
                Text.rich(
                  TextSpan(
                    style: bodyStyle,
                    children: _messageSpans(
                      S.of(context).RemoveDeviceConfirmMessage(deviceName),
                      deviceName,
                      deviceNameStyle,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppPalette.spaceXl),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(S.of(context).Cancel),
                ),
                const SizedBox(height: AppPalette.spaceMd),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.accentError,
                    foregroundColor: AppPalette.white,
                  ),
                  child: Text(S.of(context).RemoveDeviceAction),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<InlineSpan> _messageSpans(
    String message,
    String highlightedValue,
    TextStyle? highlightedStyle,
  ) {
    if (highlightedValue.isEmpty) {
      return [TextSpan(text: message)];
    }

    final matchIndex = message.indexOf(highlightedValue);
    if (matchIndex < 0) {
      return [TextSpan(text: message)];
    }

    final prefix = message.substring(0, matchIndex);
    final suffix = message.substring(matchIndex + highlightedValue.length);

    return [
      if (prefix.isNotEmpty) TextSpan(text: prefix),
      TextSpan(text: highlightedValue, style: highlightedStyle),
      if (suffix.isNotEmpty) TextSpan(text: suffix),
    ];
  }
}

class _DestructiveBadge extends StatelessWidget {
  const _DestructiveBadge({
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDark
        ? AppPalette.destructiveBg
        : AppPalette.accentError.withValues(alpha: 0.12);
    final foregroundColor =
        isDark ? AppPalette.destructiveFg : AppPalette.accentError;

    return Center(
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppPalette.radiusMd),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: foregroundColor,
          size: 22,
        ),
      ),
    );
  }
}
