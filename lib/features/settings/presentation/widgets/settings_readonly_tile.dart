import 'package:flutter/material.dart';

class SettingsReadonlyTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? value;
  final bool showDivider;

  const SettingsReadonlyTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final secondaryText = subtitle ?? value;

    return Column(
      children: [
        ListTile(
          dense: true,
          visualDensity: const VisualDensity(horizontal: 0, vertical: -1),
          minVerticalPadding: subtitle != null || value != null ? 8 : 6,
          title: Text(title),
          subtitle: secondaryText == null ? null : Text(secondaryText),
          trailing: subtitle != null && value != null ? Text(value!) : null,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}
