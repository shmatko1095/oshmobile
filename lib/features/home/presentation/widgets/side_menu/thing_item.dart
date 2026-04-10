import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/widgets/app_card.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/core/theme/text_styles.dart';
import 'package:oshmobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:oshmobile/features/home/presentation/pages/rename_device_page.dart';
import 'package:oshmobile/features/home/presentation/pages/unassign_device_dialog.dart';
import 'package:oshmobile/generated/l10n.dart';

class ThingItem extends StatelessWidget {
  final bool online;
  final bool selected;
  final String room;
  final String name;

  // final String type;
  final String id;

  const ThingItem({
    super.key,
    required this.online,
    required this.selected,
    required this.room,
    required this.name,
    // required this.type,
    required this.id,
  });

  Future<void> _onActionSelected(
    BuildContext context,
    _ThingItemAction action,
  ) async {
    switch (action) {
      case _ThingItemAction.rename:
        _onDeviceRename(context);
        return;
      case _ThingItemAction.remove:
        final approved = await _confirmUnassign(context);
        if (approved == true && context.mounted) {
          context.read<HomeCubit>().unassignDevice(id);
        }
        return;
    }
  }

  void _onDeviceRename(BuildContext context) {
    Navigator.push(
        context,
        RenameDevicePage.route(
          deviceId: id,
          name: name,
          room: room,
        ));
  }

  void _onDeviceSelected(BuildContext context) {
    context.read<HomeCubit>().selectDevice(id);
    Navigator.of(context).pop();
  }

  Widget _getIcon() {
    Color color = online ? AppPalette.accentSuccess : AppPalette.accentWarning;
    // switch (type) {
    //   case OshConfiguration.heaterType:
    //     return Icon(Icons.thermostat, color: color);
    //   default:
    return Icon(Icons.circle_rounded, size: 18, color: color);
    // }
  }

  Future<bool?> _confirmUnassign(BuildContext context) async {
    return _showUnassignDialog(context);
  }

  Future<bool?> _showUnassignDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return UnassignDeviceDialog(deviceName: name);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      confirmDismiss: (_) async => _confirmUnassign(context),
      key: ValueKey('drawer_device_$id'),
      onDismissed: (dir) => context.read<HomeCubit>().unassignDevice(id),
      direction: DismissDirection.endToStart,
      background: _buildDismissBackground(),
      child: _buildDeviceButton(context),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      color: AppPalette.destructiveBg,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: const Icon(
        Icons.delete,
        color: AppPalette.destructiveFg,
      ),
    );
  }

  Widget _buildDeviceButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color defaultTitleColor =
        isDark ? AppPalette.textSecondary : AppPalette.lightTextStrong;
    final Color defaultSubtitleColor =
        isDark ? AppPalette.textMuted : AppPalette.lightTextDisabled;
    final Color selectedTitleColor =
        isDark ? AppPalette.white : AppPalette.lightTextStrong;
    final Color titleColor = selected ? selectedTitleColor : defaultTitleColor;
    final Color subtitleColor = selected
        ? selectedTitleColor.withValues(alpha: 0.75)
        : defaultSubtitleColor;
    final Color backgroundColor = selected
        ? AppPalette.accentPrimary.withValues(alpha: 0.22)
        : (isDark ? AppPalette.surface : AppPalette.white);
    final Color? borderColor =
        selected ? AppPalette.accentPrimary.withValues(alpha: 0.4) : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: AppSolidCard(
        padding: EdgeInsets.zero,
        backgroundColor: backgroundColor,
        borderColor: borderColor,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppPalette.radiusXl),
          onTap: () => _onDeviceSelected(context),
          onLongPress: () => _onDeviceRename(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _getIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
                      if (room.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          room,
                          style: TextStyles.contentStyle
                              .copyWith(color: subtitleColor),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<_ThingItemAction>(
                  tooltip: S.of(context).DeviceActions,
                  onSelected: (action) => _onActionSelected(context, action),
                  itemBuilder: (context) => [
                    PopupMenuItem<_ThingItemAction>(
                      value: _ThingItemAction.rename,
                      child: Text(S.of(context).RenameDeviceAction),
                    ),
                    PopupMenuItem<_ThingItemAction>(
                      value: _ThingItemAction.remove,
                      child: Text(S.of(context).RemoveDeviceAction),
                    ),
                  ],
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    color: selected ? titleColor : AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _ThingItemAction {
  rename,
  remove,
}
