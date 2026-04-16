import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/selected_device_session_cubit.dart';
import 'package:oshmobile/core/analytics/osh_analytics_screen_view.dart';
import 'package:oshmobile/core/analytics/osh_analytics_screens.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/device_catalog/presentation/cubit/device_catalog_cubit.dart';
import 'package:oshmobile/features/device_management/presentation/pages/device_access_page.dart';
import 'package:oshmobile/features/device_management/presentation/pages/rename_device_page.dart';
import 'package:oshmobile/features/device_management/presentation/widgets/remove_device_dialog.dart';
import 'package:oshmobile/generated/l10n.dart';

class DeviceSettingsHubPage extends StatelessWidget {
  final String deviceId;

  static MaterialPageRoute<void> route({
    required String deviceId,
  }) =>
      MaterialPageRoute<void>(
        settings: const RouteSettings(
          name: OshAnalyticsScreens.deviceSettingsHub,
        ),
        builder: (_) => DeviceSettingsHubPage(deviceId: deviceId),
      );

  const DeviceSettingsHubPage({
    super.key,
    required this.deviceId,
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

  Future<void> _openRemoveDialog(BuildContext context, Device device) async {
    final removed = await RemoveDeviceDialog.show(
      context,
      deviceId: device.id,
      deviceSerial: device.sn,
      deviceName: _deviceDisplayName(device),
    );
    if (removed == true && context.mounted) {
      Navigator.of(context).pop();
    }
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
          child: BlocBuilder<DeviceCatalogCubit, DeviceCatalogState>(
            builder: (context, catalogState) {
              final device =
                  context.read<DeviceCatalogCubit>().getById(deviceId);
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

              final sessionState =
                  context.watch<SelectedDeviceSessionCubit>().state;
              final isCurrentSession = sessionState.deviceId == device.id;
              final canOpenInternalSettings =
                  isCurrentSession && sessionState.canOpenInternalSettings;
              final canOpenAbout =
                  isCurrentSession && sessionState.canOpenAbout;

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
                            ? () => context
                                .read<SelectedDeviceSessionCubit>()
                                .openInternalSettings(context, device)
                            : null,
                      ),
                      _SettingsTile(
                        leading: Icons.info_outline_rounded,
                        title: S.of(context).About,
                        subtitle: canOpenAbout
                            ? null
                            : S.of(context).DeviceAboutUnavailable,
                        onTap: canOpenAbout
                            ? () => context
                                .read<SelectedDeviceSessionCubit>()
                                .openAbout(context, device)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: S.of(context).DeviceActions,
                    children: [
                      _SettingsTile(
                        leading: Icons.group_outlined,
                        title: S.of(context).DeviceAccessTitle,
                        onTap: () {
                          Navigator.of(context).push(
                            DeviceAccessPage.route(
                              deviceId: device.id,
                              deviceSerial: device.sn,
                              deviceName: _deviceDisplayName(device),
                            ),
                          );
                        },
                      ),
                      _SettingsTile(
                        leading: Icons.edit_rounded,
                        title: S.of(context).RenameDeviceAction,
                        onTap: () {
                          Navigator.of(context).push(
                            RenameDevicePage.route(deviceId: device.id),
                          );
                        },
                      ),
                      _SettingsTile(
                        leading: Icons.delete_outline_rounded,
                        title: S.of(context).RemoveDeviceAction,
                        titleColor: AppPalette.destructiveFg,
                        iconColor: AppPalette.destructiveFg,
                        trailingColor:
                            AppPalette.destructiveFg.withValues(alpha: 0.72),
                        onTap: () => _openRemoveDialog(context, device),
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
