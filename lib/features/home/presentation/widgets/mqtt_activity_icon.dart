import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/cubits/mqtt/global_mqtt_cubit.dart' as global_mqtt;
import 'package:oshmobile/core/common/cubits/mqtt/mqtt_comm_cubit.dart';

/// Tiny indicator used in AppBar to show MQTT connection
/// and in-flight device communication status.
class MqttActivityIcon extends StatefulWidget {
  const MqttActivityIcon({super.key});

  @override
  State<MqttActivityIcon> createState() => _MqttActivityIconState();
}

class _MqttActivityIconState extends State<MqttActivityIcon> {
  bool _hadPending = false;
  bool _showSuccess = false;
  Timer? _successTimer;

  @override
  void dispose() {
    _successTimer?.cancel();
    super.dispose();
  }

  void _onCommChanged(BuildContext context, MqttCommState state) {
    final hasPending = state.hasPending;
    final wasPending = _hadPending;
    _hadPending = hasPending;

    // Determine if transport is in a "connected" state.
    final mqttState = context.read<global_mqtt.GlobalMqttCubit>().state;
    final isTransportConnected = !(mqttState is global_mqtt.MqttConnecting ||
        mqttState is global_mqtt.MqttDisconnected ||
        mqttState is global_mqtt.MqttError);

    // Show success only when:
    // - we had pending ops before
    // - now there are no pending ops.
    // - there is no error on the comm tracker
    // - MQTT transport is connected
    if (wasPending && !hasPending && state.lastError == null && isTransportConnected) {
      _successTimer?.cancel();
      setState(() => _showSuccess = true);
      _successTimer = Timer(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        setState(() => _showSuccess = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MqttCommCubit, MqttCommState>(
      listener: _onCommChanged,
      child: Builder(
        builder: (context) {
          final mqttState = context.watch<global_mqtt.GlobalMqttCubit>().state;
          final commState = context.watch<MqttCommCubit>().state;

          final bool hasPending = commState.hasPending;
          final bool hasCommError = commState.lastError != null;

          // Build concrete icon widget for the current state.
          final Widget child;

          // 1) Transport-level connection first.
          if (mqttState is global_mqtt.MqttConnecting) {
            child = const _SmallSpinnerTooltip(
              key: ValueKey('mqtt_connecting'),
              message: 'MQTT connecting...',
            );
          } else if (mqttState is global_mqtt.MqttDisconnected) {
            child = const Tooltip(
              key: ValueKey('mqtt_disconnected'),
              message: 'MQTT disconnected',
              child: Icon(Icons.cloud_off, size: 22),
            );
          } else if (mqttState is global_mqtt.MqttError) {
            child = const Tooltip(
              key: ValueKey('mqtt_error'),
              message: 'MQTT error',
              child: Icon(Icons.cloud_off, size: 22, color: Colors.redAccent),
            );
          } else if (_showSuccess) {
            // 2) Transport is connected and we just finished pending ops successfully.
            child = const Tooltip(
              key: ValueKey('mqtt_success'),
              message: 'Device updated',
              child: Icon(Icons.check_circle, size: 22),
            );
          } else if (hasPending) {
            // 3) Connected transport: show in-flight ops.
            child = const _RotatingSyncIcon(
              key: ValueKey('mqtt_pending'),
              tooltip: 'Waiting for device confirmation...',
            );
          } else if (hasCommError) {
            // 4) No pending, but the last op failed.
            child = Tooltip(
              key: const ValueKey('mqtt_comm_error'),
              message: commState.lastError ?? 'Last operation failed',
              child: const Icon(Icons.error_outline, size: 22, color: Colors.orangeAccent),
            );
          } else {
            // 5) Transport connected, no pending, no recent error.
            child = const Tooltip(
              key: ValueKey('mqtt_connected'),
              message: 'MQTT connected',
              child: Icon(Icons.cloud_done_outlined, size: 22),
            );
          }

          // AnimatedSwitcher will smoothly animate between different children
          // based on their keys.
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (Widget child, Animation<double> animation) {
              // Fade + slight scale for a subtle transition.
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: animation,
                  child: child,
                ),
              );
            },
            child: child,
          );
        },
      ),
    );
  }
}

class _SmallSpinnerTooltip extends StatelessWidget {
  final String message;

  const _SmallSpinnerTooltip({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CupertinoActivityIndicator(),
      ),
    );
  }
}

class _RotatingSyncIcon extends StatefulWidget {
  final String tooltip;

  const _RotatingSyncIcon({
    super.key,
    required this.tooltip,
  });

  @override
  State<_RotatingSyncIcon> createState() => _RotatingSyncIconState();
}

class _RotatingSyncIconState extends State<_RotatingSyncIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Repeat rotation while this widget is in the tree.
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
    return Tooltip(
      message: widget.tooltip,
      child: RotationTransition(
        turns: _controller,
        child: const Icon(Icons.sync, size: 22),
      ),
    );
  }
}
