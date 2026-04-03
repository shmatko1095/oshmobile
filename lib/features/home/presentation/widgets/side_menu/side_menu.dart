import 'package:flutter/material.dart';
import 'package:oshmobile/features/home/presentation/widgets/side_menu/account_drawer_header.dart';
import 'package:oshmobile/features/home/presentation/widgets/side_menu/add_device_button.dart';
import 'package:oshmobile/features/home/presentation/widgets/side_menu/item_list.dart';
import 'package:oshmobile/features/home/presentation/widgets/side_menu/logout_button.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).drawerTheme.backgroundColor ??
        Theme.of(context).scaffoldBackgroundColor;

    return Drawer(
      backgroundColor: backgroundColor,
      child: SafeArea(
        bottom: true,
        child: Column(
          children: [
            const AccountDrawerHeader(),
            const ItemList(),
            const SizedBox(height: 8),
            const AddDeviceButton(),
            const SizedBox(height: 8),
            const LogoutButton(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
