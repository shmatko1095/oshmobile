import 'package:flutter/material.dart';

/// Simple "settings-style" switch row:
/// [title] on the left, [Switch] on the right.
class SettingsSwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? subtitle;

  const SettingsSwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        ListTile(
          title: Text(
            title,
            style: theme.textTheme.bodyLarge,
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                )
              : null,
          trailing: Switch.adaptive(
            value: value,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
