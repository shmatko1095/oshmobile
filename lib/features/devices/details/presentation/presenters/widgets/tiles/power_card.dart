import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/glass_stat_card.dart';

class PowerCard extends StatelessWidget {
  const PowerCard({
    super.key,
    required this.bind,
    this.validBind,
    this.title = 'Power now',
    this.onTap,
  });

  /// Bind that returns instantaneous power in **watts**
  final String bind; // e.g. 'sensor.power'
  final String? validBind;
  final String title;
  final VoidCallback? onTap;

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
    final snapshot = context.select<DeviceSnapshotCubit, _PowerSnapshot>(
      (c) {
        final controlState = c.state.controlState.data ?? const {};
        final valid = validBind == null || validBind!.isEmpty
            ? null
            : readBind(controlState, validBind!);
        return _PowerSnapshot(
          power: asNum(readBind(controlState, bind)),
          valid: valid is bool ? valid : null,
        );
      },
    );
    final valueText =
        snapshot.valid == false ? _fmtPower(null) : _fmtPower(snapshot.power);

    return GlassStatCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.bolt, color: AppPalette.amberAccent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: statTitleColor(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valueText,
              maxLines: 1,
              style: TextStyle(
                color: statValueColor(context),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PowerSnapshot {
  const _PowerSnapshot({
    required this.power,
    required this.valid,
  });

  final num? power;
  final bool? valid;

  @override
  bool operator ==(Object other) {
    return other is _PowerSnapshot &&
        other.power == power &&
        other.valid == valid;
  }

  @override
  int get hashCode => Object.hash(power, valid);
}
