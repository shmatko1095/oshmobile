import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_state_cubit.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/glass_stat_card.dart';

// ---------- Load factor (24h duty) ----------
class LoadFactorCard extends StatelessWidget {
  const LoadFactorCard({
    super.key,
    this.percentBind, // 0..1 or 0..100
    this.hoursBind, // hours in last 24h
    this.secondsBind, // seconds in last 24h
  });

  /// Prefer this if your backend provides “duty” directly (0..1 or 0..100).
  final String? percentBind;

  /// Or provide hours the heater was ON in last 24h.
  final String? hoursBind;

  /// Or provide seconds the heater was ON in last 24h.
  final String? secondsBind;

  double? _computePercent(DeviceStateCubit c) {
    if (percentBind != null) {
      final p = asNum(c.state.get(percentBind!));
      if (p == null) return null;
      final v = p > 1 ? (p / 100.0) : p.toDouble();
      return v.clamp(0.0, 1.0);
    }
    if (hoursBind != null) {
      final h = asNum(c.state.get(hoursBind!));
      if (h == null) return null;
      return (h / 24.0).clamp(0.0, 1.0).toDouble();
    }
    if (secondsBind != null) {
      final s = asNum(c.state.get(secondsBind!));
      if (s == null) return null;
      return (s / (24 * 3600)).clamp(0.0, 1.0).toDouble();
    }
    return null;
  }

  double? _computeHours(DeviceStateCubit c, double? percent) {
    if (hoursBind != null) {
      final h = asNum(c.state.get(hoursBind!));
      if (h != null) return h.toDouble();
    }
    if (secondsBind != null) {
      final s = asNum(c.state.get(secondsBind!));
      if (s != null) return s.toDouble() / 3600.0;
    }
    if (percent != null) return percent * 24.0;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final data = context.select<DeviceStateCubit, ({double? p, double? h})>((c) {
      final p = _computePercent(c);
      final h = _computeHours(c, p);
      return (p: p, h: h);
    });

    final p = data.p; // 0..1
    final percentTxt = (p == null) ? '—' : '${(p * 100).round()}%';
    final hoursTxt = (data.h == null) ? '' : '${fmtNum(data.h, decimalsIfNeeded: 1)} h';

    return LayoutBuilder(
      builder: (context, constraints) {
        // Shrink ring on tight tiles
        final double ring = constraints.maxWidth < 220 ? 42 : 54;
        final double gap = constraints.maxWidth < 220 ? 8 : 12;

        return GlassStatCard(
          child: Row(
            children: [
              // Ring
              SizedBox(
                width: ring,
                height: ring,
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  tween: Tween<double>(begin: 0, end: p ?? 0),
                  builder: (_, value, __) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: value,
                          strokeWidth: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                        Text(
                          percentTxt,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              SizedBox(width: gap),

              // Labels (make header flexible to avoid overflow)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.schedule, size: 16, color: Colors.white70),
                        SizedBox(width: 6),
                        // <- ключ: заголовок в Flexible + ellipsis
                        Flexible(
                          child: Text(
                            'Load (24h)',
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hoursTxt.isEmpty ? '—' : hoursTxt,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
