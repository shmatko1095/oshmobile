import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_state_cubit.dart';
import 'package:oshmobile/generated/l10n.dart';

class TemperatureHeroCard extends StatelessWidget {
  final String title;

  // State binds
  final String currentBind; // e.g. 'sensor.temperature'
  final String targetBind; // e.g. 'setting.target_temperature'
  final String? nextValueBind; // e.g. 'schedule.next_target_temperature' (optional)
  final String? nextTimeBind; // e.g. 'schedule.next_time' (optional)
  final String? heaterEnabledBind; // e.g. 'status.heater_enabled' (optional)
  final String? humidityBind; // e.g. 'sensor.humidity'

  // Formatting / localization
  final String unit; // e.g. '°C'

  const TemperatureHeroCard({
    super.key,
    required this.title,
    required this.currentBind,
    required this.targetBind,
    this.nextValueBind,
    this.nextTimeBind,
    this.heaterEnabledBind,
    this.humidityBind,
    this.unit = '°C',
  });

  // ----- helpers -----
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
    DateTime? dt;
    if (t == null) return null;

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
    // Select minimal slices from state so the widget rebuilds only when those change
    final num? current = context.select<DeviceStateCubit, num?>(
      (c) => _asNum(c.state.valueOf(currentBind)),
    );
    final num? target = context.select<DeviceStateCubit, num?>(
      (c) => _asNum(c.state.valueOf(targetBind)),
    );

    final num? nextVal = nextValueBind == null
        ? null
        : context.select<DeviceStateCubit, num?>(
            (c) => _asNum(c.state.valueOf(nextValueBind!)),
          );

    final dynamic rawNextTime = nextTimeBind == null
        ? null
        : context.select<DeviceStateCubit, dynamic>(
            (c) => c.state.valueOf(nextTimeBind!),
          );

    final bool heaterEnabled = heaterEnabledBind == null
        ? false
        : context.select<DeviceStateCubit, bool>(
            (c) => _asBool(c.state.valueOf(heaterEnabledBind!)),
          );

    final dynamic humidity = humidityBind == null
        ? null
        : context.select<DeviceStateCubit, dynamic>(
            (c) => c.state.valueOf(humidityBind!),
          );

    final String currentText = '${_fmtNum(current)}$unit';
    final String targetLine = S.of(context).Target(_fmtNum(target)) + unit;

    final String nextTempStr = "${_fmtNum(nextVal)}$unit";
    final String? nextTimeStr = _fmtTime(rawNextTime);

    final String? nextLine = (nextVal != null && nextTimeStr != null)
        ? S.of(context).NextAt(nextTempStr as Object, nextTimeStr as Object)
        : null;

    final String? currentHumidity = (humidity != null) ? '${_fmtNum(humidity)}%' : null;

    return SizedBox(
      height: 230,
      child: Card(
        elevation: 3,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)],
                ),
              ),
            ),

            // content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // LEFT: title, CURRENT big, then Target/Next lines
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // title (alias / SN)
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.w700,
                                height: 1.0,
                              ),
                              child: Text(
                                currentText,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (currentHumidity != null) ...[
                              const SizedBox(width: 35),
                              Flexible(
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 48,
                                    fontWeight: FontWeight.w600,
                                    height: 1.0,
                                  ),
                                  child: Text(
                                    currentHumidity,
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 12),
                        // Target: 21.0°C
                        Text(
                          targetLine,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, height: 2),
                        ),
                        // Next: 22.5°C at 19:00   (optional)
                        if (nextLine != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            nextLine,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, height: 2),
                          ),
                        ],
                        const SizedBox(height: 15),
                      ],
                    ),
                  ),

                  // const SizedBox(width: 12),

                  // RIGHT: optional decorative icon (can be removed if not needed)
                  // const Icon(Icons.device_thermostat, color: Colors.white30, size: 56),
                ],
              ),
            ),
            // bottom-center HEAT icon (visible if heaterEnabled)
            Positioned(
              bottom: 10,
              child: AnimatedOpacity(
                opacity: heaterEnabled ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.white, size: 22),
                    const SizedBox(width: 6),
                    Text(S.of(context).Heating, style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
            // Positioned(
            //   bottom: 10,
            //   right: 10,
            //   child: const Icon(Icons.device_thermostat, color: Colors.white30, size: 56),
            // ),
          ],
        ),
      ),
    );
  }
}
