import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/cubits/auth/global_auth_cubit.dart' as global_auth;
import 'package:oshmobile/core/common/cubits/mqtt/global_mqtt_cubit.dart' as global_mqtt;
import 'package:oshmobile/core/common/cubits/mqtt/mqtt_comm_cubit.dart';

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

    final auth = context.read<global_auth.GlobalAuthCubit>();
    final mqtt = context.read<global_mqtt.GlobalMqttCubit>();

    _connectIfAuthenticated(auth, mqtt);
  }

  /// Connects MQTT if auth state is authenticated and we have required data.
  void _connectIfAuthenticated(
    global_auth.GlobalAuthCubit auth,
    global_mqtt.GlobalMqttCubit mqtt,
  ) {
    if (auth.state is! global_auth.AuthAuthenticated) return;

    final jwt = auth.getJwtUserData();
    final token = auth.getAccessToken();
    final userId = jwt?.email;

    if (userId != null && token != null) {
      mqtt.connectWith(userId: userId, token: token);
    }
  }

  /// Best-effort MQTT disconnect helper.
  void _disconnectMqtt(global_mqtt.GlobalMqttCubit mqtt) {
    mqtt.disconnect();
    context.read<MqttCommCubit>().reset();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final auth = context.read<global_auth.GlobalAuthCubit>();
    final mqtt = context.read<global_mqtt.GlobalMqttCubit>();

    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // Best-effort graceful disconnect when app goes background / closes.
      _disconnectMqtt(mqtt);
    } else if (state == AppLifecycleState.resumed) {
      // On resume – reconnect if still authenticated.
      _connectIfAuthenticated(auth, mqtt);
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
          _connectIfAuthenticated(auth, mqtt);
        } else {
          // Any non-authenticated state => disconnect.
          _disconnectMqtt(mqtt);
        }
      },
      child: widget.child,
    );
  }
}
