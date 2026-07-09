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
    this.title = 'Heating runtime',
    this.onTap,
  });

  final String? percentBind;
  final String? hoursBind;
  final String? secondsBind;
  final String title;
  final VoidCallback? onTap;

  double? _computePercent(Map<String, dynamic> controlState) {
    if (percentBind != null) {
      final p = asNum(readBind(controlState, percentBind!));
      if (p == null) return null;
      final v = p > 1 ? (p / 100.0) : p.toDouble();
      return v.clamp(0.0, 1.0);
    }
    if (hoursBind != null) {
      final h = asNum(readBind(controlState, hoursBind!));
      if (h == null) return null;
      return (h / 24.0).clamp(0.0, 1.0).toDouble();
    }
    if (secondsBind != null) {
      final s = asNum(readBind(controlState, secondsBind!));
      if (s == null) return null;
      return (s / (24 * 3600)).clamp(0.0, 1.0).toDouble();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.select<DeviceSnapshotCubit, double?>(
      (c) => _computePercent(c.state.controlState.data ?? const {}),
    );
    final percentInt = p == null ? null : (p * 100).round();
    final percentTxt = percentInt == null ? '—' : '$percentInt%';
    final periodLabel = _periodLabel(context);

    return Semantics(
      button: onTap != null,
      label: '$title, $periodLabel, $percentTxt',
      child: ExcludeSemantics(
        child: AppSolidCard(
          onTap: onTap,
          radius: AppPalette.radiusXl,
          backgroundColor: statSurfaceColor(context),
          borderColor: statBorderColor(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.insights_rounded,
                    size: 16,
                    color: statTitleColor(context),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
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
              const SizedBox(height: 10),
              Text(
                percentTxt,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: statValueColor(context),
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
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? AppPalette.white.withValues(alpha: 0.14)
                          : AppPalette.lightBorderSubtle,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppPalette.accentPrimary,
                  ),
                ),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: StatPeriodBadge(label: periodLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _periodLabel(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return languageCode == 'uk' ? '24 год' : '24h';
  }
}

/// Backward-compat wrapper, defaults to the selected card variant.
class LoadFactorCard extends StatelessWidget {
  const LoadFactorCard({
    super.key,
    this.percentBind,
    this.hoursBind,
    this.secondsBind,
    this.title = 'Heating runtime',
    this.onTap,
  });

  final String? percentBind;
  final String? hoursBind;
  final String? secondsBind;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return LoadFactorKpiCard(
      percentBind: percentBind,
      hoursBind: hoursBind,
      secondsBind: secondsBind,
      title: title,
      onTap: onTap,
    );
  }
}
