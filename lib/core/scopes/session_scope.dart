import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/cubits/mqtt/global_mqtt_cubit.dart';
import 'package:oshmobile/core/common/cubits/mqtt/mqtt_comm_cubit.dart';
import 'package:oshmobile/core/common/services/mqtt_session_controller.dart';
import 'package:oshmobile/core/di/session_di.dart';
import 'package:oshmobile/features/home/presentation/bloc/home_cubit.dart';

/// SessionScope:
/// - Enters GetIt session scope on mount.
/// - Starts MQTT connect via [MqttSessionController].
/// - Provides session-scoped cubits (HomeCubit, GlobalMqttCubit, MqttCommCubit).
/// - Leaves session scope on dispose.
///
/// A new SessionScope must be created on each login.
class SessionScope extends StatefulWidget {
  final String userId;
  final String token;
  final Widget child;

  const SessionScope({
    super.key,
    required this.userId,
    required this.token,
    required this.child,
  });

  @override
  State<SessionScope> createState() => _SessionScopeState();
}

class _SessionScopeState extends State<SessionScope> {
  bool _ready = false;
  Object? _error;

  int? _sessionGen;

  // Session-scoped instances (resolved after SessionDi.enter()).
  late final HomeCubit _home;
  late final GlobalMqttCubit _mqtt;
  late final MqttCommCubit _comm;
  late final MqttSessionController _sessionController;

  @override
  void initState() {
    super.initState();

    // IMPORTANT:
    // When we recreate SessionScope (re-login), Flutter may build the new
    // SessionScope before disposing the previous one (different key).
    // If we enter GetIt scope immediately, previous dispose() could pop our
    // fresh scope. Enter on the next frame to avoid this race.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_enterAndBootstrap());
    });
  }

  Future<void> _enterAndBootstrap() async {
    // 1) Enter session DI (creates `session:<userId>` scope).
    final gen = await SessionDi.enter(
      SessionCredentials(userId: widget.userId, token: widget.token),
    );
    _sessionGen = gen;

    // 2) Resolve session singletons.
    _home = locator<HomeCubit>();
    _mqtt = locator<GlobalMqttCubit>();
    _comm = locator<MqttCommCubit>();
    _sessionController = locator<MqttSessionController>();

    // 3) Wait until MQTT connect is completed.
    try {
      await _sessionController.ready;
    } catch (e) {
      _error = e;
      // Still render the app; MQTT cubit will be in error state.
    }

    if (!mounted) return;
    setState(() => _ready = true);
  }

  @override
  void dispose() {
    // Leave session scope last. Child widgets are disposed before this
    // State.dispose(), so device-scoped cubits can still use session resources
    // while closing.
    final gen = _sessionGen;
    if (gen != null) {
      unawaited(SessionDi.leave(gen: gen));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Keep _error for debug / future UI surfacing.
    // ignore: unused_local_variable
    final err = _error;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _home),
        BlocProvider.value(value: _mqtt),
        BlocProvider.value(value: _comm),
      ],
      child: widget.child,
    );
  }
}
