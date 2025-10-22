import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_state_cubit.dart';

class ToggleTile extends StatelessWidget {
  final String title, bind;
  final void Function(BuildContext, bool) onChanged;

  const ToggleTile({super.key, required this.title, required this.bind, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final value = (context.select<DeviceStateCubit, dynamic>((c) => c.state.valueOf(bind)) as bool?) ?? false;
    return Card(
        child: Padding(
      padding: const EdgeInsets.all(8),
      child: SwitchListTile(title: Text(title), value: value, onChanged: (v) => onChanged(context, v)),
    ));
  }
}
