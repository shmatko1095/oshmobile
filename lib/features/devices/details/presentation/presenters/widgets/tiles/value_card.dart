import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/network/mqtt/signal_command.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_state_cubit.dart';

class ValueCard extends StatelessWidget {
  final String title, bind;
  final String? suffix;

  const ValueCard({
    super.key,
    required this.title,
    required this.bind,
    this.suffix,
  });

  String _fmt(dynamic v) {
    if (v == null) return '—';
    if (v is num) {
      final hasFraction = (v % 1) != 0;
      return hasFraction ? v.toStringAsFixed(1) : v.toStringAsFixed(0);
    }
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final dynamic raw = context.select<DeviceStateCubit, dynamic>(
      (c) => c.state.get(Signal(bind)),
    );
    final String valueText = _fmt(raw);
    final String full = suffix != null && valueText != '—' ? '$valueText$suffix' : valueText;

    return Card(
      color: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // title
            Text(
              title,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            // animated value
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
              child: Text(
                full,
                key: ValueKey(full),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
