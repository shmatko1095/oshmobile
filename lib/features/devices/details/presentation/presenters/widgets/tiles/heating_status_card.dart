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
  });

  final String bind;
  final String title;

  bool _asBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v.toLowerCase() == 'true' || v == '1';
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isHeating = context.select<DeviceSnapshotCubit, bool>(
      (c) => _asBool(readBind(c.state.telemetry.data ?? const {}, bind)),
    );

    final borderColor = isHeating
        ? AppPalette.accentWarning.withValues(alpha: 0.45)
        : AppPalette.borderSoft;

    return AppSolidCard(
      radius: AppPalette.radiusXl,
      backgroundColor: AppPalette.surfaceRaised,
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
                          : AppPalette.surfaceAlt,
                    ),
                    child: Icon(
                      isHeating
                          ? Icons.local_fire_department_rounded
                          : Icons.power_settings_new_rounded,
                      color: isHeating
                          ? AppPalette.accentWarning
                          : AppPalette.textSecondary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppPalette.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                        : AppPalette.textPrimary,
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
