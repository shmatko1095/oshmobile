import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/utils/thermostat_heating_state.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/glass_stat_card.dart';
import 'package:oshmobile/generated/l10n.dart';

class HeatingStatusHorizontalCard extends StatelessWidget {
  const HeatingStatusHorizontalCard({
    super.key,
    required this.bind,
    this.onTap,
  });

  final String bind;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final heatingState = context.select<DeviceSnapshotCubit, bool?>(
      (cubit) => parseThermostatHeatingState(
        readBind(
          cubit.state.controlState.data ?? const <String, dynamic>{},
          bind,
        ),
      ),
    );
    final s = S.of(context);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final animationDuration =
        disableAnimations ? Duration.zero : AppPalette.motionBase;
    final isHeating = heatingState == true;
    final statusText = switch (heatingState) {
      true => 'ON',
      false => 'OFF',
      null => '—',
    };
    final semanticsLabel = switch (heatingState) {
      true => s.ThermostatHeatingStatusOn,
      false => s.ThermostatHeatingStatusOff,
      null => s.ThermostatHeatingStatusUnavailable,
    };
    final accentColor = isHeating
        ? AppPalette.accentWarning
        : heatingState == false
            ? statTitleColor(context)
            : statMutedColor(context);
    final borderColor = isHeating
        ? AppPalette.accentWarning.withValues(alpha: 0.23)
        : statBorderColor(context);
    final surfaceColor = statSurfaceColor(context);
    final activeSurfaceColor = Color.alphaBlend(
      AppPalette.accentWarning.withValues(
        alpha: isDarkSurface(context) ? 0.16 : 0.10,
      ),
      surfaceColor,
    );
    final radius = BorderRadius.circular(AppPalette.radiusXl);

    return Semantics(
      button: onTap != null,
      container: true,
      liveRegion: true,
      label: semanticsLabel,
      onTap: onTap,
      child: ExcludeSemantics(
        child: AnimatedContainer(
          key: const ValueKey('heating-status-horizontal-card'),
          duration: animationDuration,
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isHeating ? activeSurfaceColor : surfaceColor,
            borderRadius: radius,
            border: Border.all(color: borderColor),
            boxShadow: isHeating
                ? <BoxShadow>[
                    BoxShadow(
                      color: AppPalette.accentWarning.withValues(alpha: 0.18),
                      blurRadius: 30,
                      spreadRadius: -6,
                    ),
                    BoxShadow(
                      color: AppPalette.accentWarning.withValues(alpha: 0.09),
                      blurRadius: 56,
                      spreadRadius: -14,
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: AppPalette.transparent,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppPalette.spaceLg,
                  vertical: AppPalette.spaceMd,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 280;
                    final iconExtent = compact ? 36.0 : 40.0;

                    return Row(
                      children: [
                        AnimatedContainer(
                          key: const ValueKey(
                            'heating-status-horizontal-icon',
                          ),
                          duration: animationDuration,
                          curve: Curves.easeOutCubic,
                          width: iconExtent,
                          height: iconExtent,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isHeating
                                ? AppPalette.accentWarning.withValues(
                                    alpha: 0.19,
                                  )
                                : statSurfaceAltColor(context),
                          ),
                          child: Icon(
                            switch (heatingState) {
                              true => Icons.local_fire_department_rounded,
                              false => Icons.power_settings_new_rounded,
                              null => Icons.help_outline_rounded,
                            },
                            color: accentColor,
                            size: compact ? 20 : 22,
                          ),
                        ),
                        SizedBox(width: compact ? AppPalette.spaceMd : 18),
                        Expanded(
                          child: Text(
                            s.Heating,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: statTitleColor(context),
                              fontSize: compact ? 14 : 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (onTap != null) ...[
                          const SizedBox(width: AppPalette.spaceSm),
                          Icon(
                            Icons.show_chart_rounded,
                            size: 16,
                            color: statMutedColor(context),
                          ),
                        ],
                        SizedBox(width: compact ? AppPalette.spaceMd : 18),
                        SizedBox(
                          width: compact ? 60 : 68,
                          child: AnimatedSwitcher(
                            key: const ValueKey(
                              'heating-status-horizontal-value',
                            ),
                            duration: animationDuration,
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                            child: FittedBox(
                              key: ValueKey<bool?>(heatingState),
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                statusText,
                                maxLines: 1,
                                style: TextStyle(
                                  color: isHeating
                                      ? AppPalette.accentWarning
                                      : statValueColor(context),
                                  fontSize: compact ? 26 : 28,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
