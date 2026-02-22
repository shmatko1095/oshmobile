import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/widgets/app_card.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/core/theme/text_styles.dart';
import 'package:oshmobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:oshmobile/features/home/presentation/pages/rename_device_page.dart';
import 'package:oshmobile/features/home/presentation/pages/unassign_device_dialog.dart';

class ThingItem extends StatelessWidget {
  final bool online;
  final String room;
  final String name;

  // final String type;
  final String id;

  const ThingItem({
    super.key,
    required this.online,
    required this.room,
    required this.name,
    // required this.type,
    required this.id,
  });

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
    Color color = online ? AppPalette.accentSuccess : AppPalette.textMuted;
    // switch (type) {
    //   case OshConfiguration.heaterType:
    //     return Icon(Icons.thermostat, color: color);
    //   default:
    return Icon(Icons.circle_rounded, color: color);
    // }
  }

  Future<bool?> _confirmUnassign(BuildContext context) async {
    return _showUnassignDialog(context);
  }

  Future<bool?> _showUnassignDialog(BuildContext context) async {
    return await showCupertinoDialog<bool>(
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
      //Key("thing_item_$sn")
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: AppSolidCard(
        padding: EdgeInsets.zero,
        backgroundColor: AppPalette.surface,
        child: ListTile(
          onTap: () => _onDeviceSelected(context),
          onLongPress: () => _onDeviceRename(context),
          leading: _getIcon(),
          title: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle:
              room.isEmpty ? null : Text(room, style: TextStyles.contentStyle),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AppPalette.textMuted,
          ),
        ),
      ),
    );
  }
}
