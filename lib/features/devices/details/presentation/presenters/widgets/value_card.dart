import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_state_cubit.dart';

class ValueCard extends StatelessWidget {
  final String title, bind;
  final String? suffix;

  const ValueCard({super.key, required this.title, required this.bind, this.suffix});

  @override
  Widget build(BuildContext context) {
    final v = context.select<DeviceStateCubit, dynamic>((c) => c.state.valueOf(bind));
    final text = v == null ? '—' : v.toString();
    return Card(
        child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('$text${suffix ?? ''}', style: const TextStyle(fontSize: 18)),
      ]),
    ));
  }
}
