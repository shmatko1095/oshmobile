import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_state_cubit.dart';

class DeltaTCard extends StatelessWidget {
  const DeltaTCard({
    super.key,
    required this.inletBind, // e.g. 'sensor.water_inlet_temp'
    required this.outletBind, // e.g. 'sensor.water_outlet_temp'
    this.unit = '°C',
    this.title = 'ΔT (out − in)',
  });

  final String inletBind;
  final String outletBind;
  final String unit;
  final String title;

  num? _asNum(dynamic v) {
    if (v is num) return v;
    if (v is String) return num.tryParse(v);
    return null;
  }

  String _fmtNum(num? v, {int decimalsIfNeeded = 1}) {
    if (v == null) return '—';
    return (v % 1 == 0) ? v.toStringAsFixed(0) : v.toStringAsFixed(decimalsIfNeeded);
  }

  @override
  Widget build(BuildContext context) {
    final data = context.select<DeviceStateCubit, ({num? inT, num? outT, num? dT})>((c) {
      final inT = _asNum(c.state.get(inletBind));
      final outT = _asNum(c.state.get(outletBind));
      final dT = (inT != null && outT != null) ? (outT - inT) : null;
      return (inT: inT, outT: outT, dT: dT);
    });

    final String dtTxt = '${_fmtNum(data.dT)}$unit';
    final String inlet = '${_fmtNum(data.inT)}$unit';
    final String outlet = '${_fmtNum(data.outT)}$unit';

    final Color accent = (data.dT == null) ? Colors.white : (data.dT! >= 0 ? Colors.orangeAccent : Colors.cyanAccent);

    return LayoutBuilder(
      builder: (context, c) {
        final bool tight = c.maxWidth < 220;
        final double gap = tight ? 6 : 8;

        return Card(
          color: Colors.transparent,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.sync_alt, size: 16, color: Colors.white70),
                    SizedBox(width: gap),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // big ΔT value
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(color: accent, fontSize: 22, fontWeight: FontWeight.w800),
                  child: Text(dtTxt),
                ),

                const SizedBox(height: 8),

                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.call_received, size: 14, color: Colors.white54),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: c.maxWidth / 2 - 24),
                          child: Text(
                            'In: $inlet',
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white60),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.call_made, size: 14, color: Colors.white54),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: c.maxWidth / 2 - 24),
                          child: Text(
                            'Out: $outlet',
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white60),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
