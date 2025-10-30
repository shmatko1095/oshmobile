import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/network/mqtt/signal_command.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_state_cubit.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/glass_stat_card.dart';

class OutletTempCard extends StatelessWidget {
  const OutletTempCard({super.key, required this.bind, this.title = 'Outlet temperature', this.unit = '°C'});

  final String bind; // e.g. 'sensor.water_outlet_temp'
  final String title;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final v = context.select<DeviceStateCubit, num?>((c) => asNum(c.state.get(Signal(bind))));
    return GlassStatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.opacity, size: 16, color: Colors.white70),
            SizedBox(width: 6),
            Text('Outlet temperature', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),
          Text(
            '${fmtNum(v)}$unit',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
