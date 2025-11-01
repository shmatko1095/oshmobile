import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/network/mqtt/signal_command.dart';
import 'package:oshmobile/features/devices/details/domain/models/telemetry.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_state_cubit.dart';
import 'package:oshmobile/features/schedule/presentation/cubit/schedule_cubit.dart';
import 'package:oshmobile/generated/l10n.dart';

class TemperatureMinimalPanel extends StatelessWidget {
  const TemperatureMinimalPanel({
    super.key,
    required this.currentBind,
    this.heaterEnabledBind,
    this.onTap,
    this.unit = '°C',
    this.height,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    this.borderRadius = 20,
  });

  final Signal currentBind;
  final Signal? heaterEnabledBind;

  final String unit;
  final double? height;
  final EdgeInsets padding;
  final double borderRadius;
  final void Function()? onTap;

  // helpers
  num? _asNum(dynamic v) {
    if (v is num) return v;
    if (v is String) return num.tryParse(v);
    return null;
  }

  bool _asBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v.toLowerCase() == 'true' || v == '1';
    return false;
  }

  String _fmtNum(num? v) {
    if (v == null) return '—';
    final d = v.toDouble();
    if (d.isNaN || d.isInfinite) return '—';
    return d.toStringAsFixed(1);
  }

  String? _fmtTimeOfDay(TimeOfDay? t) {
    if (t == null) return null;
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    final num? current = context
        .select<DeviceStateCubit, num?>((c) => _asNum(Telemetry.maybeFrom(c.state.getDynamic(currentBind))?.chipTemp));
    final num? target = context
        .select<DeviceScheduleCubit, num?>((c) => c.currentPoint() != null ? _asNum(c.currentPoint()!.max) : null);
    final num? nextVal =
        context.select<DeviceScheduleCubit, num?>((c) => c.nextPoint() != null ? _asNum(c.nextPoint()!.max) : null);
    final TimeOfDay? rawNextTime = context.select<DeviceScheduleCubit, TimeOfDay?>((c) => c.nextPoint()?.time);

    final bool heaterOn = heaterEnabledBind != null
        ? context.select<DeviceStateCubit, bool>((c) => _asBool(c.state.get(heaterEnabledBind!)))
        : false;

    final String centerText = _fmtNum(current);
    final String topLine = s.Target(_fmtNum(target)) + unit;
    final String? nextTimeStr = _fmtTimeOfDay(rawNextTime);
    final String? bottomLine =
        (nextVal != null && nextTimeStr != null) ? s.NextAt('${_fmtNum(nextVal)}$unit', nextTimeStr) : null;

    final panel = Container(
      padding: padding,
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 180),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 160),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  child: Text(
                    topLine,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 140,
                      fontWeight: FontWeight.w300,
                      height: 1.0,
                    ),
                    child: Text(
                      centerText,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.fade,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (bottomLine != null)
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 160),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    child: Text(
                      bottomLine,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (heaterOn) ...[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        s.Heating,
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    final clipped = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: panel,
    );

    if (height != null) {
      return SizedBox(height: height, child: clipped);
    }
    return clipped;
  }
}
