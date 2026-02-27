import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/widgets/app_card.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/glass_stat_card.dart';

class LoadFactorKpiCard extends StatelessWidget {
  const LoadFactorKpiCard({
    super.key,
    this.percentBind,
    this.hoursBind,
    this.secondsBind,
  });

  final String? percentBind;
  final String? hoursBind;
  final String? secondsBind;

  double? _computePercent(Map<String, dynamic> telemetry) {
    if (percentBind != null) {
      final p = asNum(readBind(telemetry, percentBind!));
      if (p == null) return null;
      final v = p > 1 ? (p / 100.0) : p.toDouble();
      return v.clamp(0.0, 1.0);
    }
    if (hoursBind != null) {
      final h = asNum(readBind(telemetry, hoursBind!));
      if (h == null) return null;
      return (h / 24.0).clamp(0.0, 1.0).toDouble();
    }
    if (secondsBind != null) {
      final s = asNum(readBind(telemetry, secondsBind!));
      if (s == null) return null;
      return (s / (24 * 3600)).clamp(0.0, 1.0).toDouble();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.select<DeviceSnapshotCubit, double?>(
      (c) => _computePercent(c.state.telemetry.data ?? const {}),
    );
    final percentInt = p == null ? null : (p * 100).round();
    final percentTxt = percentInt == null ? '—' : '$percentInt%';

    return AppSolidCard(
      radius: AppPalette.radiusXl,
      backgroundColor: AppPalette.surfaceRaised,
      borderColor: AppPalette.borderSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.insights_rounded,
                  size: 16, color: AppPalette.textSecondary),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Heating activity (24h)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppPalette.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            percentTxt,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppPalette.textPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppPalette.radiusPill),
            child: LinearProgressIndicator(
              value: p ?? 0,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.14),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppPalette.accentPrimary),
            ),
          ),
          const Spacer(),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'last 24h',
              style: TextStyle(
                color: AppPalette.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Backward-compat wrapper, defaults to the selected card variant.
class LoadFactorCard extends StatelessWidget {
  const LoadFactorCard({
    super.key,
    this.percentBind,
    this.hoursBind,
    this.secondsBind,
  });

  final String? percentBind;
  final String? hoursBind;
  final String? secondsBind;

  @override
  Widget build(BuildContext context) {
    return LoadFactorKpiCard(
      percentBind: percentBind,
      hoursBind: hoursBind,
      secondsBind: secondsBind,
    );
  }
}
