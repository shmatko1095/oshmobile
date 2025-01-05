import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/features/home/presentation/bloc/home_cubit.dart';

class ThingItem extends StatelessWidget {
  final bool unassignDeviceAllowed;
  final bool online;
  final String room;
  final String name;
  final String sn;

  const ThingItem({
    super.key,
    required this.unassignDeviceAllowed,
    required this.online,
    required this.room,
    required this.name,
    required this.sn,
  });

  Widget _buildStatusIcon(bool online) {
    return Icon(
      online ? Icons.circle : Icons.circle_outlined,
      color: online ? Colors.green : Colors.blueGrey,
      size: 16.0,
      shadows: online
          ? [
              const Shadow(
                blurRadius: 20.0,
                color: Colors.green,
              ),
            ]
          : null,
    );
  }

  void _onDeviceRename(BuildContext context) {
    // HomeCubit homeCubit = context.read<HomeCubit>();
    // RenameThingDialog.show(
    //     context: context,
    //     name: device.name,
    //     onChanged: (name) => homeCubit.renameDevice(device.sn, name));
  }

  void _onDeviceSelected(BuildContext context) {
    // context.read<HomeCubit>().selectDevice(device.sn);
    // Scaffold.of(context).openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      confirmDismiss: (_) async => unassignDeviceAllowed,
      key: Key("thing_item_$name"),
      onDismissed: (dir) => context.read<HomeCubit>().unassignDevice(sn),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete),
      ),
      child: ListTile(
        leading: const Icon(Icons.home),
        title: Text(name),
        subtitle: room.isEmpty ? null : Text(room),
        onTap: () => _onDeviceSelected(context),
        onLongPress: () => _onDeviceRename(context),
        trailing: _buildStatusIcon(online),
      ),
    );
  }
}
