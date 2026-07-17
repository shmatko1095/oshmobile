import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/generated/l10n.dart';

class ThermostatHeatingIndicator extends StatelessWidget {
  const ThermostatHeatingIndicator({
    super.key,
    required this.active,
    required this.selected,
    required this.ultraCompact,
  });

  final bool? active;
  final bool selected;
  final bool ultraCompact;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final visualSize = ultraCompact ? const Size(22, 31) : const Size(28, 40);

    return Offstage(
      offstage: !selected,
      child: Semantics(
        container: true,
        liveRegion: true,
        label: _semanticsLabel(context),
        child: IgnorePointer(
          child: AnimatedSwitcher(
            duration: disableAnimations ? Duration.zero : AppPalette.motionBase,
            reverseDuration:
                disableAnimations ? Duration.zero : AppPalette.motionBase,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.94, end: 1).animate(animation),
                child: child,
              ),
            ),
            child: active == true
                ? TweenAnimationBuilder<double>(
                    key: const ValueKey('thermostat-heating-active'),
                    duration: disableAnimations
                        ? Duration.zero
                        : const Duration(milliseconds: 1380),
                    curve: Curves.linear,
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, progress, child) {
                      final motion = _indicatorMotion(progress);
                      return Opacity(
                        key:
                            const ValueKey('thermostat-heating-motion-opacity'),
                        opacity: motion.opacity,
                        child: Transform.scale(
                          key:
                              const ValueKey('thermostat-heating-motion-scale'),
                          scale: motion.scale,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: AppPalette.accentWarning.withValues(
                                    alpha: motion.glowOpacity,
                                  ),
                                  blurRadius: 18,
                                  spreadRadius: -5,
                                ),
                              ],
                            ),
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: Image.asset(
                      'assets/images/thermostat_fire.png',
                      key: const ValueKey('thermostat-heating-fire-image'),
                      width: visualSize.width,
                      height: visualSize.height,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  )
                : const SizedBox.shrink(
                    key: ValueKey('thermostat-heating-inactive'),
                  ),
          ),
        ),
      ),
    );
  }

  String _semanticsLabel(BuildContext context) {
    final s = S.of(context);
    return switch (active) {
      true => s.ThermostatHeatingStatusOn,
      false => s.ThermostatHeatingStatusOff,
      null => s.ThermostatHeatingStatusUnavailable,
    };
  }
}

({double opacity, double scale, double glowOpacity}) _indicatorMotion(
  double progress,
) {
  const entranceShare = 180 / 1380;
  if (progress <= entranceShare) {
    final entrance = Curves.easeOutCubic.transform(
      (progress / entranceShare).clamp(0.0, 1.0),
    );
    return (
      opacity: entrance,
      scale: 0.94 + 0.06 * entrance,
      glowOpacity: 0.18 * entrance,
    );
  }

  final pulseProgress =
      ((progress - entranceShare) / (1 - entranceShare)).clamp(0.0, 1.0);
  final pulse = math.pow(math.sin(2 * math.pi * pulseProgress), 2).toDouble();
  return (
    opacity: 1 - 0.12 * pulse,
    scale: 1 + 0.06 * pulse,
    glowOpacity: 0.18 + 0.08 * pulse,
  );
}
