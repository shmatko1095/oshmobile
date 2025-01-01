import 'package:flutter/material.dart';
import 'package:oshmobile/core/common/widgets/colored_divider.dart';
import 'package:oshmobile/features/home/presentation/widgets/side_menu/account_drawer_header.dart';
import 'package:oshmobile/features/home/presentation/widgets/side_menu/add_device_button.dart';
import 'package:oshmobile/features/home/presentation/widgets/side_menu/logout_button.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const AccountDrawerHeader(),
          // Expanded(child: ItemList(unassignAllowed: !user.isDemoUser)),
          const AddDeviceButton(),
          const ColoredDivider(thickness: 1.5),
          const LogoutButton(),
        ],
      ),
    );
  }
}
