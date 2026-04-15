import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/analytics/osh_analytics_screen_view.dart';
import 'package:oshmobile/core/analytics/osh_analytics_screens.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:oshmobile/features/home/presentation/pages/rename_device_page.dart';
import 'package:oshmobile/features/home/presentation/pages/unassign_device_dialog.dart';
import 'package:oshmobile/generated/l10n.dart';

class DeviceSettingsHubPage extends StatelessWidget {
  final String deviceId;
  final VoidCallback? openInternalSettingsAction;

  static MaterialPageRoute<void> route({
    required String deviceId,
    required VoidCallback? openInternalSettingsAction,
  }) =>
      MaterialPageRoute<void>(
        settings: const RouteSettings(
          name: OshAnalyticsScreens.deviceSettingsHub,
        ),
        builder: (_) => DeviceSettingsHubPage(
          deviceId: deviceId,
          openInternalSettingsAction: openInternalSettingsAction,
        ),
      );

  const DeviceSettingsHubPage({
    super.key,
    required this.deviceId,
    required this.openInternalSettingsAction,
  });

  String _deviceDisplayName(Device device) {
    String take(String value) => value.trim();

    final alias = take(device.userData.alias);
    if (alias.isNotEmpty) return alias;

    final sn = take(device.sn);
    if (sn.isNotEmpty) return sn;

    final modelName = take(device.modelName);
    if (modelName.isNotEmpty) return modelName;

    return take(device.id);
  }

  String _deviceRoom(Device device) => device.userData.description.trim();

  Future<void> _openRename(BuildContext context, Device device) async {
    await Navigator.of(context).push(
      RenameDevicePage.route(
        deviceId: device.id,
        name: _deviceDisplayName(device),
        room: _deviceRoom(device),
      ),
    );
  }

  Future<void> _removeDevice(BuildContext context, Device device) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (_) => UnassignDeviceDialog(
        deviceName: _deviceDisplayName(device),
      ),
    );
    if (approved != true || !context.mounted) return;

    final homeCubit = context.read<HomeCubit>();
    Navigator.of(context).pop();
    homeCubit.unassignDevice(device.id);
  }

  @override
  Widget build(BuildContext context) {
    return OshAnalyticsScreenView(
      screenName: OshAnalyticsScreens.deviceSettingsHub,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            S.of(context).Settings,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: SafeArea(
          child: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) {
              final homeCubit = context.read<HomeCubit>();
              final device = homeCubit.getDeviceById(deviceId);
              if (device == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      S.of(context).NoDeviceSelected,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final canOpenInternalSettings =
                  openInternalSettingsAction != null;

              return ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                children: [
                  _SectionCard(
                    title: S.of(context).Settings,
                    children: [
                      _SettingsTile(
                        leading: Icons.tune_rounded,
                        title: S.of(context).DeviceInternalSettings,
                        subtitle: canOpenInternalSettings
                            ? null
                            : S.of(context).DeviceInternalSettingsUnavailable,
                        onTap: canOpenInternalSettings
                            ? openInternalSettingsAction
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: S.of(context).DeviceActions,
                    children: [
                      _SettingsTile(
                        leading: Icons.edit_rounded,
                        title: S.of(context).RenameDeviceAction,
                        onTap: () => _openRename(context, device),
                      ),
                      _SettingsTile(
                        leading: Icons.delete_outline_rounded,
                        title: S.of(context).RemoveDeviceAction,
                        titleColor: AppPalette.destructiveFg,
                        iconColor: AppPalette.destructiveFg,
                        trailingColor:
                            AppPalette.destructiveFg.withValues(alpha: 0.72),
                        onTap: () => _removeDevice(context, device),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
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
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
            ),
          ),
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              const Divider(height: 1, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.leading,
    required this.title,
    this.subtitle,
    this.onTap,
    this.titleColor,
    this.iconColor,
    this.trailingColor,
  });

  final IconData leading;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? titleColor;
  final Color? iconColor;
  final Color? trailingColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onTap != null;
    final resolvedTitleColor =
        enabled ? titleColor : theme.disabledColor.withValues(alpha: 0.9);
    final resolvedIconColor =
        enabled ? iconColor : theme.disabledColor.withValues(alpha: 0.9);
    final resolvedTrailingColor =
        enabled ? trailingColor : theme.disabledColor.withValues(alpha: 0.9);

    return ListTile(
      enabled: enabled,
      leading: Icon(leading, color: resolvedIconColor),
      title: Text(
        title,
        style: titleColor == null && enabled
            ? null
            : TextStyle(color: resolvedTitleColor),
      ),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: resolvedTrailingColor ?? theme.disabledColor,
      ),
      onTap: onTap,
    );
  }
}
