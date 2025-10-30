import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/network/mqtt/signal_command.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_state_cubit.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/glass_stat_card.dart';

class PowerCard extends StatelessWidget {
  const PowerCard({super.key, required this.bind});

  /// Bind that returns instantaneous power in **watts**
  final String bind; // e.g. 'sensor.power'

  String _fmtPower(num? w) {
    if (w == null) return '—';
    if (w.abs() >= 1000) {
      final kw = w / 1000.0;
      return '${fmtNum(kw)} kW';
    }
    return '${fmtNum(w, decimalsIfNeeded: 0)} W';
  }

  @override
  Widget build(BuildContext context) {
    final power = context.select<DeviceStateCubit, num?>((c) => asNum(c.state.get(Signal(bind))));
    return GlassStatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.bolt, color: Colors.amberAccent, size: 18),
            SizedBox(width: 8),
            Text('Power now', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),
          Text(
            _fmtPower(power),
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
