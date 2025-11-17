import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/cubits/auth/global_auth_cubit.dart' as global_auth;
import 'package:oshmobile/core/common/cubits/mqtt/global_mqtt_cubit.dart' as global_mqtt;

/// High-level coordinator that keeps MQTT connection in sync with Auth state
/// and app lifecycle. Put it above MaterialApp.
class AuthMqttCoordinator extends StatefulWidget {
  final Widget child;

  const AuthMqttCoordinator({super.key, required this.child});

  @override
  State<AuthMqttCoordinator> createState() => _AuthMqttCoordinatorState();
}

class _AuthMqttCoordinatorState extends State<AuthMqttCoordinator> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // If we already have a session on startup – connect MQTT.
    final auth = context.read<global_auth.GlobalAuthCubit>();
    final mqtt = context.read<global_mqtt.GlobalMqttCubit>();

    if (auth.state is global_auth.AuthAuthenticated) {
      final userId = auth.getJwtUserData()?.email;
      final token = auth.getAccessToken();
      if (userId != null && token != null) {
        mqtt.connectWith(userId: userId, token: token);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final auth = context.read<global_auth.GlobalAuthCubit>();
    final mqtt = context.read<global_mqtt.GlobalMqttCubit>();

    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // Best-effort graceful disconnect when app goes background / closes.
      mqtt.disconnect();
    } else if (state == AppLifecycleState.resumed) {
      if (auth.state is global_auth.AuthAuthenticated) {
        final userId = auth.getJwtUserData()?.uuid;
        final token = auth.getAccessToken();
        if (userId != null && token != null) {
          mqtt.connectWith(userId: userId, token: token);
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<global_auth.GlobalAuthCubit, global_auth.GlobalAuthState>(
      listenWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
      listener: (context, state) {
        final auth = context.read<global_auth.GlobalAuthCubit>();
        final mqtt = context.read<global_mqtt.GlobalMqttCubit>();

        if (state is global_auth.AuthAuthenticated) {
          final userId = auth.getJwtUserData()?.email;
          final token = auth.getAccessToken();
          if (userId != null && token != null) {
            mqtt.connectWith(userId: userId, token: token);
          }
        } else {
          // Any non-authenticated state => disconnect.
          mqtt.disconnect();
        }
      },
      child: widget.child,
    );
  }
}
