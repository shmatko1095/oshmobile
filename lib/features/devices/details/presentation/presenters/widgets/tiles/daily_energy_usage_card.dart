import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/daily_energy_usage_cubit.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/daily_energy_usage_state.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/glass_stat_card.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/daily_energy_usage_cache.dart';
import 'package:oshmobile/generated/l10n.dart';

class DailyEnergyUsageCard extends StatelessWidget {
  const DailyEnergyUsageCard({
    super.key,
    required this.title,
    required this.cacheNamespace,
    this.cache,
    this.onTap,
  });

  final String title;
  final String cacheNamespace;
  final DailyEnergyUsageCache? cache;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DailyEnergyUsageCubit(
        telemetryHistory: context.read<DeviceFacade>().telemetryHistory,
        persistentCache: cache,
        persistentCacheNamespace: cacheNamespace,
      )..ensureLoaded(),
      child: _DailyEnergyUsageCardContent(
        title: title,
        onTap: onTap,
      ),
    );
  }
}

class _DailyEnergyUsageCardContent extends StatelessWidget {
  const _DailyEnergyUsageCardContent({
    required this.title,
    required this.onTap,
  });

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final state = context.watch<DailyEnergyUsageCubit>().state;
    final periodLabel = _periodLabel(context);
    final valueText = _formatKwh(state.energyWh);
    final statusText = _statusText(s, state);

    return Semantics(
      button: onTap != null,
      label: '$title, $periodLabel, $valueText, $statusText',
      child: ExcludeSemantics(
        child: GlassStatCard(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    color: AppPalette.accentSuccess,
                    size: 18,
                  ),
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
              const SizedBox(height: 10),
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

  String _formatKwh(double? energyWh) {
    if (energyWh == null) return '—';
    final energyKwh = energyWh / 1000.0;
    final decimals = energyKwh.abs() < 10 ? 2 : 1;
    return '${energyKwh.toStringAsFixed(decimals)} kWh';
  }

  String _periodLabel(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return languageCode == 'uk' ? '24 год' : '24h';
  }

  String _statusText(S s, DailyEnergyUsageState state) {
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
}
