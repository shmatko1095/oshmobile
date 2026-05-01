import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/settings/domain/models/settings_snapshot.dart';
import 'package:oshmobile/features/settings/domain/ui/settings_ui_schema.dart';
import 'package:oshmobile/features/settings/presentation/utils/settings_text_localizer.dart';
import 'package:oshmobile/features/settings/presentation/widgets/device_settings_field_tile.dart';

class DeviceSettingsInlineGroupCard extends StatelessWidget {
  final SettingsUiSchema schema;
  final SettingsUiGroup group;
  final SettingsSnapshot snapshot;
  final SettingsTextLocalizer textLocalizer;

  const DeviceSettingsInlineGroupCard({
    super.key,
    required this.schema,
    required this.group,
    required this.snapshot,
    this.textLocalizer = const SettingsTextLocalizer(),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fields = schema.fieldsInGroup(group.id).toList(growable: false);
    if (fields.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppPalette.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              textLocalizer.groupTitle(context, group),
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
          for (var i = 0; i < fields.length; i++)
            DeviceSettingsFieldTile(
              field: fields[i],
              snapshot: snapshot,
              showDivider: i != fields.length - 1,
              textLocalizer: textLocalizer,
            ),
        ],
      ),
    );
  }
}

class DeviceSettingsFieldsCard extends StatelessWidget {
  final List<SettingsUiField> fields;
  final SettingsSnapshot snapshot;
  final SettingsTextLocalizer textLocalizer;

  const DeviceSettingsFieldsCard({
    super.key,
    required this.fields,
    required this.snapshot,
    this.textLocalizer = const SettingsTextLocalizer(),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppPalette.radiusXl),
      ),
      child: Column(
        children: [
          for (var i = 0; i < fields.length; i++)
            DeviceSettingsFieldTile(
              field: fields[i],
              snapshot: snapshot,
              showDivider: i != fields.length - 1,
              textLocalizer: textLocalizer,
            ),
        ],
      ),
    );
  }
}

class DeviceSettingsGroupNavigationCard extends StatelessWidget {
  final SettingsUiGroup group;
  final VoidCallback onTap;
  final SettingsTextLocalizer textLocalizer;

  const DeviceSettingsGroupNavigationCard({
    super.key,
    required this.group,
    required this.onTap,
    this.textLocalizer = const SettingsTextLocalizer(),
  });

  @override
  Widget build(BuildContext context) {
    final title = textLocalizer.groupTitle(context, group);
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppPalette.radiusXl),
      ),
      child: ListTile(
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
    );
  }
}
