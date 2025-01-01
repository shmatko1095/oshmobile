import 'package:flutter/material.dart';
import 'package:oshmobile/generated/l10n.dart';

class AddDeviceButton extends StatelessWidget {
  const AddDeviceButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.add, color: Colors.blue),
      title: Text(S.of(context).AddDevice),
      onTap: null,
      // onTap: () => Navigator.of(context).push(
      //   NewDeviceForm.route(
      //       homeCubit: context.read<HomeCubit>(),
      //       title: S.of(context).addDevice,
      //       handler: context.read<HomeCubit>().assignDevice),
      // )
    );
  }
}
