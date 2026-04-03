import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/widgets/app_card.dart';
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
        ? AppPalette.accentWarning.withValues(alpha: 0.45)
        : statBorderColor(context);

    return AppSolidCard(
      onTap: onTap,
      radius: AppPalette.radiusXl,
      backgroundColor: statSurfaceColor(context),
      borderColor: borderColor,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: AppPalette.motionBase,
                opacity: isHeating ? 1 : 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppPalette.radiusXl),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppPalette.accentWarning.withValues(alpha: 0.20),
                        AppPalette.accentWarning.withValues(alpha: 0.07),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: AppPalette.motionBase,
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isHeating
                          ? AppPalette.accentWarning.withValues(alpha: 0.22)
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: statTitleColor(context),
                        fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }
}
