import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/domain/device_snapshot.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/core/common/widgets/loader.dart';
import 'package:oshmobile/features/settings/domain/models/settings_snapshot.dart';
import 'package:oshmobile/features/settings/domain/ui/settings_ui_schema.dart';
import 'package:oshmobile/features/settings/presentation/widgets/device_settings_group_cards.dart';
import 'package:oshmobile/generated/l10n.dart';

class DeviceSettingsContent extends StatelessWidget {
  final SettingsUiSchema schema;
  final bool isRoot;
  final List<SettingsUiGroup> groups;
  final List<SettingsUiField> fields;
  final Future<void> Function(SettingsUiGroup group) onOpenGroup;

  const DeviceSettingsContent({
    super.key,
    required this.schema,
    required this.isRoot,
    required this.groups,
    required this.fields,
    required this.onOpenGroup,
  });

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty && fields.isEmpty) {
      return Center(
        child: Text(S.of(context).DeviceNoSettingsYet),
      );
    }

    return BlocBuilder<DeviceSnapshotCubit, DeviceSnapshot>(
      buildWhen: (prev, next) => prev.settings != next.settings,
      builder: (context, snap) {
        final slice = snap.settings;

        switch (slice.status) {
          case DeviceSliceStatus.idle:
          case DeviceSliceStatus.loading:
            return const Loader();
          case DeviceSliceStatus.error:
            if (slice.data == null) {
              return _DeviceSettingsErrorView(
                  message: slice.error ?? 'Unknown error');
            }
            return _DeviceSettingsListView(
              schema: schema,
              isRoot: isRoot,
              groups: groups,
              fields: fields,
              snapshot: slice.data!,
              onOpenGroup: onOpenGroup,
            );
          case DeviceSliceStatus.ready:
          case DeviceSliceStatus.saving:
            final data = slice.data;
            if (data == null) {
              return const _DeviceSettingsErrorView(
                  message: 'Settings state is empty');
            }
            return _DeviceSettingsListView(
              schema: schema,
              isRoot: isRoot,
              groups: groups,
              fields: fields,
              snapshot: data,
              onOpenGroup: onOpenGroup,
            );
        }
      },
    );
  }
}

class _DeviceSettingsListView extends StatelessWidget {
  final SettingsUiSchema schema;
  final bool isRoot;
  final List<SettingsUiGroup> groups;
  final List<SettingsUiField> fields;
  final SettingsSnapshot snapshot;
  final Future<void> Function(SettingsUiGroup group) onOpenGroup;

  const _DeviceSettingsListView({
    required this.schema,
    required this.isRoot,
    required this.groups,
    required this.fields,
    required this.snapshot,
    required this.onOpenGroup,
  });

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    if (isRoot) {
      for (final group in groups) {
        items.add(
          group.presentation == SettingsUiGroupPresentation.screen
              ? DeviceSettingsGroupNavigationCard(
                  group: group,
                  onTap: () => onOpenGroup(group),
                )
              : DeviceSettingsInlineGroupCard(
                  schema: schema,
                  group: group,
                  snapshot: snapshot,
                ),
        );
      }
    } else {
      if (fields.isNotEmpty) {
        items.add(
          DeviceSettingsFieldsCard(
            fields: fields,
            snapshot: snapshot,
          ),
        );
      }

      for (final group in groups) {
        items.add(
          DeviceSettingsGroupNavigationCard(
            group: group,
            onTap: () => onOpenGroup(group),
          ),
        );
      }
    }

    return RefreshIndicator(
      onRefresh: () => context.read<DeviceFacade>().settings.get(force: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 4 : 12),
              child: items[i],
            ),
        ],
      ),
    );
  }
}

class _DeviceSettingsErrorView extends StatelessWidget {
  final String message;

  const _DeviceSettingsErrorView({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTimeout = message.toLowerCase().contains('timeout');
    final friendly = isTimeout
        ? S.of(context).DeviceOfflineOrNotResponding
        : S.of(context).FailedToLoadSettings;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 32,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              friendly,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  context.read<DeviceFacade>().settings.get(force: true),
              icon: const Icon(Icons.refresh),
              label: Text(S.of(context).Retry),
            ),
          ],
        ),
      ),
    );
  }
}
