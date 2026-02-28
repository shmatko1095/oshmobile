import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/glass_stat_card.dart';

// ---------- Inlet / Outlet water temperature ----------
class InletTempCard extends StatelessWidget {
  const InletTempCard(
      {super.key,
      required this.bind,
      this.title = 'Inlet temperature',
      this.unit = '°C'});

  final String bind; // e.g. 'sensor.water_inlet_temp'
  final String title;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final v = context.select<DeviceSnapshotCubit, num?>(
      (c) => asNum(readBind(c.state.controlState.data ?? const {}, bind)),
    );
    return GlassStatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.water_drop, size: 16, color: Colors.white70),
            SizedBox(width: 6),
            Text('Inlet temperature',
                style: TextStyle(
                    color: Colors.white70, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),
          Text(
            '${fmtNum(v)}$unit',
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
