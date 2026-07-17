import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/core/common/widgets/app_card.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/daily_energy_usage_cubit.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/daily_energy_usage_state.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/glass_stat_card.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/daily_energy_usage_cache.dart';
import 'package:oshmobile/generated/l10n.dart';

class DailyStats24hCard extends StatelessWidget {
  const DailyStats24hCard({
    super.key,
    required this.energySeriesKey,
    required this.heatingActivityBind,
    required this.cacheNamespace,
    this.cache,
    this.compact = false,
  });

  final String energySeriesKey;
  final String heatingActivityBind;
  final String cacheNamespace;
  final DailyEnergyUsageCache? cache;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DailyEnergyUsageCubit(
        telemetryHistory: context.read<DeviceFacade>().telemetryHistory,
        persistentCache: cache,
        persistentCacheNamespace: cacheNamespace,
        aggregateSeriesKey: energySeriesKey,
      )..startPolling(),
      child: Builder(
        builder: (context) {
          final s = S.of(context);
          final energyState = context.watch<DailyEnergyUsageCubit>().state;
          final heatingFraction = context.select<DeviceSnapshotCubit, double?>(
            (cubit) => _heatingFraction(
              cubit.state.controlState.data ?? const <String, dynamic>{},
            ),
          );
          final energyText = _formatKwh(energyState.energyWh);
          final heatingText = heatingFraction == null
              ? '—'
              : '${(heatingFraction * 100).round()}%';
          final energyStatus = _energyStatusText(s, energyState);
          final energyStatusLabel =
              energyStatus.isEmpty ? '' : ', $energyStatus';

          return Semantics(
            container: true,
            label: '${s.DailyStatsPeriod24h}. '
                '${s.TelemetryHistoryMetricEnergyUsed}: '
                '$energyText$energyStatusLabel. '
                '${s.TelemetryHistoryMetricLoadFactor}: $heatingText.',
            child: ExcludeSemantics(
              child: AppSolidCard(
                key: const ValueKey('daily-stats-24h-card'),
                padding: EdgeInsets.all(
                  compact ? AppPalette.spaceMd : AppPalette.spaceLg,
                ),
                backgroundColor: statSurfaceColor(context),
                borderColor: statBorderColor(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 16,
                          color: statMutedColor(context),
                        ),
                        const SizedBox(width: AppPalette.spaceSm),
                        Expanded(
                          child: Text(
                            s.DailyStatsPeriod24h,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: statMutedColor(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: compact ? AppPalette.spaceSm : AppPalette.spaceLg,
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final useHorizontalLayout = compact
                            ? constraints.maxWidth >= 224
                            : constraints.maxWidth >= 260 &&
                                MediaQuery.textScalerOf(context).scale(1) <=
                                    1.25;
                        final energyMetric = _buildMetric(
                          context,
                          icon: Icons.bolt_rounded,
                          iconColor: AppPalette.accentSuccess,
                          title: s.TelemetryHistoryMetricEnergyUsed,
                          value: energyText,
                          valueKey: const ValueKey(
                            'daily-stats-24h-energy-value',
                          ),
                        );
                        final heatingMetric = _buildMetric(
                          context,
                          icon: Icons.timer_outlined,
                          iconColor: AppPalette.orangeAccent,
                          title: s.TelemetryHistoryMetricLoadFactor,
                          value: heatingText,
                          valueKey: const ValueKey(
                            'daily-stats-24h-heating-value',
                          ),
                        );

                        if (!useHorizontalLayout) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              energyMetric,
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: compact
                                      ? AppPalette.spaceMd
                                      : AppPalette.spaceLg,
                                ),
                                child: Divider(
                                  height: 1,
                                  color: _separatorColor(context),
                                ),
                              ),
                              heatingMetric,
                            ],
                          );
                        }

                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: energyMetric),
                              SizedBox(
                                width: compact
                                    ? AppPalette.spaceMd
                                    : AppPalette.spaceLg,
                              ),
                              Container(
                                width: 1,
                                color: _separatorColor(context),
                              ),
                              SizedBox(
                                width: compact
                                    ? AppPalette.spaceMd
                                    : AppPalette.spaceLg,
                              ),
                              Expanded(child: heatingMetric),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetric(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required Key valueKey,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: compact ? 16 : 18, color: iconColor),
            const SizedBox(width: AppPalette.spaceSm),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: statTitleColor(context),
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  height: 1.12,
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          height: compact ? AppPalette.spaceSm : AppPalette.spaceMd,
        ),
        AnimatedSwitcher(
          duration: AppPalette.motionBase,
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: FittedBox(
            key: valueKey,
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                color: statValueColor(context),
                fontSize: compact ? 24 : 28,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  double? _heatingFraction(Map<String, dynamic> controlState) {
    final raw = asNum(readBind(controlState, heatingActivityBind));
    if (raw == null) return null;
    final normalized = raw > 1 ? raw / 100 : raw.toDouble();
    return normalized.clamp(0.0, 1.0).toDouble();
  }

  String _formatKwh(double? energyWh) {
    if (energyWh == null) return '—';
    final energyKwh = energyWh / 1000;
    final decimals = energyKwh.abs() < 10 ? 2 : 1;
    return '${energyKwh.toStringAsFixed(decimals)} kWh';
  }

  String _energyStatusText(S s, DailyEnergyUsageState state) {
    if (state.status == DailyEnergyUsageStatus.loading) {
      return s.MqttStatusUpdating;
    }
    if (state.status == DailyEnergyUsageStatus.error) {
      return s.MqttStatusError;
    }
    if (state.energyWh == null) {
      return s.NoDataYet;
    }
    return state.isFromPersistentCache ? s.MqttStatusUpdating : '';
  }

  Color _separatorColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppPalette.separator
        : AppPalette.lightBorder;
  }
}
