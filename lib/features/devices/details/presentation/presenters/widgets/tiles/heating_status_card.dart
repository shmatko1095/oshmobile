import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/glass_stat_card.dart';

class HeatingStatusCard extends StatelessWidget {
  const HeatingStatusCard({
    super.key,
    required this.bind,
    this.title = 'Heating',
    this.onTap,
  });

  final String bind;
  final String title;
  final VoidCallback? onTap;

  bool _asBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v.toLowerCase() == 'true' || v == '1';
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isHeating = context.select<DeviceSnapshotCubit, bool>(
      (c) => _asBool(readBind(c.state.controlState.data ?? const {}, bind)),
    );

    final borderColor = isHeating
        ? AppPalette.accentWarning.withValues(alpha: 0.23)
        : statBorderColor(context);
    final radius = BorderRadius.circular(AppPalette.radiusXl);

    return AnimatedContainer(
      duration: AppPalette.motionBase,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: isHeating
            ? <BoxShadow>[
                BoxShadow(
                  color: AppPalette.accentWarning.withValues(alpha: 0.21),
                  blurRadius: 26,
                  spreadRadius: -8,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppPalette.accentWarning.withValues(alpha: 0.11),
                  blurRadius: 48,
                  spreadRadius: -18,
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
          child: Ink(
            padding: const EdgeInsets.all(AppPalette.spaceLg),
            decoration: BoxDecoration(
              color: statSurfaceColor(context),
              borderRadius: radius,
              border: Border.all(color: borderColor),
              gradient: isHeating
                  ? RadialGradient(
                      center: const Alignment(-0.82, -0.64),
                      radius: 1.55,
                      colors: [
                        AppPalette.accentWarning.withValues(alpha: 0.28),
                        AppPalette.accentWarning.withValues(alpha: 0.14),
                        AppPalette.accentWarning.withValues(alpha: 0.056),
                        AppPalette.transparent,
                      ],
                      stops: const [0, 0.38, 0.72, 1],
                    )
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: AppPalette.motionBase,
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isHeating
                            ? AppPalette.accentWarning.withValues(alpha: 0.19)
                            : statSurfaceAltColor(context),
                      ),
                      child: Icon(
                        isHeating
                            ? Icons.local_fire_department_rounded
                            : Icons.power_settings_new_rounded,
                        color: isHeating
                            ? AppPalette.accentWarning
                            : statTitleColor(context),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
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
                    if (onTap != null)
                      Icon(
                        Icons.show_chart_rounded,
                        size: 16,
                        color: statMutedColor(context),
                      ),
                  ],
                ),
                const Spacer(),
                AnimatedSwitcher(
                  duration: AppPalette.motionBase,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(scale: anim, child: child),
                  ),
                  child: Text(
                    isHeating ? 'ON' : 'OFF',
                    key: ValueKey(isHeating),
                    style: TextStyle(
                      color: isHeating
                          ? AppPalette.accentWarning
                          : statValueColor(context),
                      fontWeight: FontWeight.w800,
                      fontSize: 30,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
