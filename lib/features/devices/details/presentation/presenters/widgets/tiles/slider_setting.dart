import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/glass_stat_card.dart';

class SliderSetting extends StatefulWidget {
  final String title;
  final String bind;
  final double min, max, step;
  final void Function(BuildContext, double) onSubmit;

  const SliderSetting({
    super.key,
    required this.title,
    required this.bind,
    required this.min,
    required this.max,
    required this.step,
    required this.onSubmit,
  });

  @override
  State<SliderSetting> createState() => _SliderSettingState();
}

class _SliderSettingState extends State<SliderSetting> {
  double? _val;

  double _snap(double x) {
    final step = widget.step <= 0 ? 1.0 : widget.step;
    final snapped = widget.min + (((x - widget.min) / step).round() * step);
    return snapped.clamp(widget.min, widget.max);
  }

  int get _decimals {
    // derive decimals needed for display based on step (e.g., 0.5 -> 1, 0.25 -> 2)
    final s = widget.step.abs();
    if (s == 0) return 0;
    final e = (s.toString().contains('e') || s.toString().contains('E'))
        ? (() {
            // scientific notation
            final parts = s.toString().toLowerCase().split('e-');
            if (parts.length == 2) return int.tryParse(parts[1]) ?? 0;
            return 0;
          }())
        : math.max(
            0,
            s.toString().split('.').length == 2
                ? s.toString().split('.')[1].length
                : 0);
    return e;
  }

  String _fmt(double v) => v.toStringAsFixed(_decimals);

  int? get _divisions {
    if (widget.step <= 0) return null;
    final d = (widget.max - widget.min) / widget.step;
    // only set divisions when it's effectively an integer
    final r = d.round();
    return ((d - r).abs() < 1e-6) ? r : null;
  }

  @override
  Widget build(BuildContext context) {
    final current = (context.select<DeviceSnapshotCubit, dynamic>(
          (c) => readBind(c.state.telemetry.data ?? const {}, widget.bind),
        ) as num?)
            ?.toDouble() ??
        (widget.min + widget.max) / 2;

    final v = (_val ?? current).clamp(widget.min, widget.max);

    return GlassStatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, size: 18, color: Colors.white70),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              AnimatedSwitcher(
                duration: AppPalette.motionFast,
                transitionBuilder: (c, a) =>
                    FadeTransition(opacity: a, child: c),
                child: Text(
                  _fmt(v),
                  key: ValueKey(v.toStringAsFixed(_decimals)),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: AppPalette.accentPrimary,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
              overlayColor: AppPalette.accentPrimary.withValues(alpha: 0.15),
              valueIndicatorColor: AppPalette.surfaceAlt,
            ),
            child: Slider(
              value: v,
              min: widget.min,
              max: widget.max,
              divisions: _divisions,
              label: _fmt(v),
              onChanged: (x) => setState(() => _val = _snap(x)),
              onChangeEnd: (x) {
                final snapped = _snap(x);
                setState(() => _val = snapped);
                widget.onSubmit(context, snapped);
              },
            ),
          ),
          Row(
            children: [
              Text(
                _fmt(widget.min),
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const Spacer(),
              Text(
                _fmt(widget.max),
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
