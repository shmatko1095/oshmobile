import 'package:flutter/material.dart';
import 'package:oshmobile/features/home/presentation/pages/add_device_page.dart';
import 'package:oshmobile/generated/l10n.dart';

class AddDeviceButton extends StatelessWidget {
  const AddDeviceButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.add, color: Colors.blue),
      title: Text(S.of(context).AddDevice),
      onTap: () => Navigator.push(context, AddDevicePage.route()),
    );
  }
}
