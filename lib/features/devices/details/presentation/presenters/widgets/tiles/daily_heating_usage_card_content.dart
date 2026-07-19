import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/widgets/app_card.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/daily_heating_usage_cubit.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/daily_heating_usage_state.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/glass_stat_card.dart';
import 'package:oshmobile/generated/l10n.dart';

class DailyHeatingUsageCardContent extends StatelessWidget {
  const DailyHeatingUsageCardContent({
    super.key,
    required this.title,
    required this.onTap,
  });

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DailyHeatingUsageCubit>().state;
    final value = state.loadFactorPercent;
    final valueText = value == null ? '—' : '${value.round()}%';
    final periodLabel =
        Localizations.localeOf(context).languageCode == 'uk' ? '24 год' : '24h';
    final s = S.of(context);
    final statusText = switch (state.status) {
      DailyHeatingUsageStatus.loading => s.MqttStatusUpdating,
      DailyHeatingUsageStatus.error => s.MqttStatusError,
      _ when value == null => s.NoDataYet,
      _ => '',
    };

    return Semantics(
      button: onTap != null,
      label: '$title, $periodLabel, $valueText, $statusText',
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
                valueText,
                maxLines: 1,
                style: TextStyle(
                  color: statValueColor(context),
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppPalette.radiusPill),
                child: LinearProgressIndicator(
                  value: value == null ? 0 : (value / 100).clamp(0, 1),
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
}
