import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/glass_stat_card.dart';

class PowerMetricCard extends StatelessWidget {
  const PowerMetricCard({
    super.key,
    required this.valueBind,
    this.validBind,
    required this.title,
    required this.unit,
    required this.icon,
    required this.accentColor,
    this.decimals = 1,
    this.onTap,
  });

  final String valueBind;
  final String? validBind;
  final String title;
  final String unit;
  final IconData icon;
  final Color accentColor;
  final int decimals;
  final VoidCallback? onTap;

  String _format(num? value) {
    if (value == null) return '—';
    final valueText = value % 1 == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(decimals);
    return '$valueText $unit';
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = context.select<DeviceSnapshotCubit, _PowerMetricSnapshot>(
      (c) {
        final controlState = c.state.controlState.data ?? const {};
        final valid = validBind == null || validBind!.isEmpty
            ? null
            : readBind(controlState, validBind!);
        final validValue = valid is bool ? valid : null;
        return _PowerMetricSnapshot(
          value: asNum(readBind(controlState, valueBind)),
          valid: validValue,
        );
      },
    );
    final valueText =
        snapshot.valid == false ? _format(null) : _format(snapshot.value);

    return GlassStatCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: statTitleColor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          AnimatedSwitcher(
            duration: AppPalette.motionBase,
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: Align(
              key: ValueKey(valueText),
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  valueText,
                  maxLines: 1,
                  style: TextStyle(
                    color: statValueColor(context),
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PowerMetricSnapshot {
  const _PowerMetricSnapshot({
    required this.value,
    required this.valid,
  });

  final num? value;
  final bool? valid;

  @override
  bool operator ==(Object other) {
    return other is _PowerMetricSnapshot &&
        other.value == value &&
        other.valid == valid;
  }

  @override
  int get hashCode => Object.hash(value, valid);
}
