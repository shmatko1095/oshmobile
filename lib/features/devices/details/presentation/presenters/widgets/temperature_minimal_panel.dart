import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_state_cubit.dart';
import 'package:oshmobile/generated/l10n.dart';

class TemperatureMinimalPanel extends StatelessWidget {
  const TemperatureMinimalPanel({
    super.key,
    required this.currentBind, // 'sensor.temperature'
    required this.targetBind, // 'setting.target_temperature'
    this.nextValueBind, // 'schedule.next_target_temperature' (optional)
    this.nextTimeBind, // 'schedule.next_time' (optional)
    this.heaterEnabledBind, // 'status.heater_enabled' (optional)
    this.onTap,
    this.unit = '°C',
    this.height,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    this.borderRadius = 20, // скру=гление только для клипа (без декора)
  });

  final String currentBind;
  final String targetBind;
  final String? nextValueBind;
  final String? nextTimeBind;
  final String? heaterEnabledBind;

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
    return d.toStringAsFixed(1); // ← всегда один знак
  }

  String? _fmtTime(dynamic t) {
    if (t == null) return null;
    DateTime? dt;
    if (t is DateTime) {
      dt = t;
    } else if (t is num) {
      final ms = t.toInt().toString().length >= 13 ? t.toInt() : t.toInt() * 1000;
      dt = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: false);
    } else if (t is String) {
      final hhmm = RegExp(r'^\d{1,2}:\d{2}$');
      if (hhmm.hasMatch(t)) return t;
      final asInt = int.tryParse(t);
      if (asInt != null) {
        final ms = t.length >= 13 ? asInt : asInt * 1000;
        dt = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: false);
      } else {
        dt = DateTime.tryParse(t);
      }
    }
    if (dt == null) return null;
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    final num? current = context.select<DeviceStateCubit, num?>((c) => _asNum(c.state.valueOf(currentBind)));
    final num? target = context.select<DeviceStateCubit, num?>((c) => _asNum(c.state.valueOf(targetBind)));
    final num? nextVal = nextValueBind == null
        ? null
        : context.select<DeviceStateCubit, num?>((c) => _asNum(c.state.valueOf(nextValueBind!)));
    final dynamic rawNextTime =
        nextTimeBind == null ? null : context.select<DeviceStateCubit, dynamic>((c) => c.state.valueOf(nextTimeBind!));
    final bool heaterOn = heaterEnabledBind == null
        ? false
        : context.select<DeviceStateCubit, bool>((c) => _asBool(c.state.valueOf(heaterEnabledBind!)));

    final String centerText = _fmtNum(current);
    final String topLine = s.Target(_fmtNum(target)) + unit;
    final String? nextTimeStr = _fmtTime(rawNextTime);
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

                // центральная огромная температура
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 140, // крупнее для "минималиста"
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
