import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_state_cubit.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/glass_stat_card.dart';

class ValueCard extends StatelessWidget {
  final String title;
  final String bind;
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
      (c) => c.state.get(bind),
    );
    final String valueText = _fmt(raw);
    final String full =
        suffix != null && valueText != '—' ? '$valueText$suffix' : valueText;

    return GlassStatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
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
    );
  }
}
