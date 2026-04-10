import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/cubits/mqtt/global_mqtt_cubit.dart'
    as global_mqtt;
import 'package:oshmobile/core/common/cubits/mqtt/mqtt_comm_cubit.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/generated/l10n.dart';

class MqttActivityIcon extends StatelessWidget {
  const MqttActivityIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final mqttState = context.watch<global_mqtt.GlobalMqttCubit>().state;
    final commState = context.watch<MqttCommCubit>().state;
    final presentation = _resolveMqttStatus(
      s: S.of(context),
      mqttState: mqttState,
      commState: commState,
    );

    return AnimatedSwitcher(
      duration: AppPalette.motionBase,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        );
      },
      child: presentation == null
          ? const SizedBox(
              key: ValueKey('mqtt_hidden'),
              width: 0,
              height: 0,
            )
          : _MqttStatusIcon(
              key: ValueKey(presentation.kind),
              presentation: presentation,
            ),
    );
  }
}

_MqttStatusPresentation? _resolveMqttStatus({
  required S s,
  required global_mqtt.GlobalMqttState mqttState,
  required MqttCommState commState,
}) {
  if (mqttState is global_mqtt.MqttError) {
    return _MqttStatusPresentation(
      kind: _MqttStatusKind.error,
      label: s.MqttStatusError,
      icon: const Icon(Icons.error_outline_rounded, size: 22),
      foregroundColor: AppPalette.accentWarning,
    );
  }

  if (commState.lastError != null) {
    return _MqttStatusPresentation(
      kind: _MqttStatusKind.error,
      label: s.MqttStatusError,
      icon: const Icon(Icons.error_outline_rounded, size: 22),
      foregroundColor: AppPalette.accentWarning,
    );
  }

  if (commState.hasPending) {
    return _MqttStatusPresentation(
      kind: _MqttStatusKind.updating,
      label: s.MqttStatusUpdating,
      icon: const Icon(Icons.sync_rounded, size: 22),
      foregroundColor: AppPalette.accentPrimary,
    );
  }

  return null;
}

enum _MqttStatusKind {
  updating,
  error,
}

class _MqttStatusPresentation {
  const _MqttStatusPresentation({
    required this.kind,
    required this.label,
    required this.icon,
    required this.foregroundColor,
  });

  final _MqttStatusKind kind;
  final String label;
  final Widget icon;
  final Color foregroundColor;
}

class _MqttStatusIcon extends StatelessWidget {
  const _MqttStatusIcon({
    super.key,
    required this.presentation,
  });

  final _MqttStatusPresentation presentation;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: presentation.label,
      child: Material(
        color: AppPalette.transparent,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: IconTheme(
              data: IconThemeData(color: presentation.foregroundColor),
              child: presentation.kind == _MqttStatusKind.updating
                  ? _RotatingStatusIcon(child: presentation.icon)
                  : presentation.icon,
            ),
          ),
        ),
      ),
    );
  }
}

class _RotatingStatusIcon extends StatefulWidget {
  const _RotatingStatusIcon({
    required this.child,
  });

  final Widget child;

  @override
  State<_RotatingStatusIcon> createState() => _RotatingStatusIconState();
}

class _RotatingStatusIconState extends State<_RotatingStatusIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: widget.child,
    );
  }
}
