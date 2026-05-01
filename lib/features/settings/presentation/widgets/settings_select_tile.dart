import 'package:flutter/material.dart';

class SettingsSelectTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<String> options;
  final String? value;
  final bool showDivider;
  final ValueChanged<String>? onChanged;
  final String Function(String option) optionTitleBuilder;

  const SettingsSelectTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.options,
    required this.value,
    required this.showDivider,
    required this.onChanged,
    required this.optionTitleBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safeOptions = options.isEmpty ? const <String>['-'] : options;
    final safeValue = safeOptions.contains(value) ? value : safeOptions.first;

    return Column(
      children: [
        ListTile(
          dense: true,
          visualDensity: const VisualDensity(horizontal: 0, vertical: -1),
          minVerticalPadding: subtitle != null ? 8 : 6,
          title: Text(title, style: theme.textTheme.bodyLarge),
          subtitle: subtitle == null
              ? null
              : Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.7),
                  ),
                ),
          trailing: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: safeValue,
              items: safeOptions
                  .map(
                    (opt) => DropdownMenuItem<String>(
                      value: opt,
                      child: Text(opt == '-' ? opt : optionTitleBuilder(opt)),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (v) {
                if (v == null ||
                    onChanged == null ||
                    safeOptions.first == '-') {
                  return;
                }
                onChanged!(v);
              },
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}
