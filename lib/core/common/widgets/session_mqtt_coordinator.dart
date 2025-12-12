import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/cubits/auth/global_auth_cubit.dart' as global_auth;
import 'package:oshmobile/core/common/cubits/mqtt/global_mqtt_cubit.dart';

class SessionMqttCoordinator extends StatefulWidget {
  final Widget child;

  const SessionMqttCoordinator({super.key, required this.child});

  @override
  State<SessionMqttCoordinator> createState() => _SessionMqttCoordinatorState();
}

class _SessionMqttCoordinatorState extends State<SessionMqttCoordinator> with WidgetsBindingObserver {
  late final global_auth.GlobalAuthCubit _auth;
  late final GlobalMqttCubit _mqtt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _auth = context.read<global_auth.GlobalAuthCubit>();
    _mqtt = context.read<GlobalMqttCubit>();

    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // ✅ No repo calls here. GlobalMqttCubit.close() will shutdown transport.
    super.dispose();
  }

  void _sync() {
    if (_auth.state is! global_auth.AuthAuthenticated) return;

    final jwt = _auth.getJwtUserData();
    final token = _auth.getAccessToken();
    final userId = jwt?.email;

    if (userId == null || token == null) return;

    if (_mqtt.isConnected) {
      _mqtt.updateCredentials(userId: userId, token: token);
    } else {
      _mqtt.connectWith(userId: userId, token: token);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _mqtt.disconnect();
    } else if (state == AppLifecycleState.resumed) {
      _sync();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<global_auth.GlobalAuthCubit, global_auth.GlobalAuthState>(
      listenWhen: (prev, curr) => prev.revision != curr.revision,
      listener: (_, __) => _sync(),
      child: widget.child,
    );
  }
}
