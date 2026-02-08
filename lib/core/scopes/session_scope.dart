import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/cubits/app/app_lifecycle_cubit.dart';
import 'package:oshmobile/core/common/cubits/auth/global_auth_cubit.dart' as global_auth;
import 'package:oshmobile/core/common/cubits/mqtt/global_mqtt_cubit.dart';
import 'package:oshmobile/core/common/cubits/mqtt/mqtt_comm_cubit.dart';
import 'package:oshmobile/core/common/services/mqtt_session_controller.dart';
import 'package:oshmobile/core/di/session_di.dart';
import 'package:oshmobile/features/home/presentation/bloc/home_cubit.dart';

/// SessionScope:
/// - Enters GetIt session scope on mount.
/// - Starts MQTT connect via [MqttSessionController].
/// - Provides session-scoped cubits (HomeCubit, GlobalMqttCubit, MqttCommCubit).
/// - Listens to app lifecycle to disconnect on background and reconnect on resume.
/// - Listens to auth changes to update MQTT credentials on token refresh.
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

  // Coalesce lifecycle-driven connect/disconnect/updateCredentials.
  Future<void>? _disconnectInFlight;
  Future<void>? _resumeInFlight;
  Future<void>? _credsUpdateInFlight;

  // Track last token to avoid reconnect loops on the same creds.
  String? _lastToken;
  AppLifecycleState _lastLifecycle = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();

    // Avoid GetIt scope race with previous SessionScope dispose.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_enterAndBootstrap());
    });
  }

  Future<void> _enterAndBootstrap() async {
    // Enter session DI scope.
    final gen = await SessionDi.enter(
      SessionCredentials(userId: widget.userId, token: widget.token),
    );
    _sessionGen = gen;

    // Resolve session singletons.
    _home = locator<HomeCubit>();
    _mqtt = locator<GlobalMqttCubit>();
    _comm = locator<MqttCommCubit>();
    _sessionController = locator<MqttSessionController>();

    _lastToken = widget.token;

    // Wait until initial MQTT connect completes.
    try {
      await _sessionController.ready;
    } catch (e) {
      _error = e;
      // Keep session alive even if MQTT failed; UI can show mqtt error state.
    }

    if (!mounted) return;
    setState(() => _ready = true);
  }

  @override
  void dispose() {
    // Leave session scope last.
    final gen = _sessionGen;
    if (gen != null) {
      unawaited(SessionDi.leave(gen: gen));
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Lifecycle handling
  // ---------------------------------------------------------------------------

  void _onLifecycle(AppLifecycleStateVm life) {
    if (!_ready) return;

    final s = life.state;
    _lastLifecycle = s;

    if (s == AppLifecycleState.paused || s == AppLifecycleState.inactive || s == AppLifecycleState.detached) {
      unawaited(_safeDisconnect());
      return;
    }

    if (s == AppLifecycleState.resumed) {
      unawaited(_safeResume());
    }
  }

  Future<void> _safeDisconnect() {
    return _disconnectInFlight ??= _mqtt.disconnect().whenComplete(() {
      _disconnectInFlight = null;
    });
  }

  /// IMPORTANT:
  /// On Android/iOS the OS can kill/abort TCP sockets in background.
  /// mqtt_client may still report "connected" even though the socket is dead.
  Future<void> _safeResume() async {
    _resumeInFlight ??= () async {
      // Ensure any in-flight disconnect completes first.
      if (_disconnectInFlight != null) {
        try {
          await _disconnectInFlight;
        } catch (_) {}
      }

      final creds = _readAuthCredsOrFallback();
      if (creds == null) return;

      final delays = <Duration>[
        Duration.zero,
        const Duration(seconds: 1),
        const Duration(seconds: 2),
        const Duration(seconds: 4),
      ];

      for (final delay in delays) {
        if (!mounted || _lastLifecycle != AppLifecycleState.resumed) return;
        if (delay > Duration.zero) {
          await Future.delayed(delay);
        }
        if (!mounted || _lastLifecycle != AppLifecycleState.resumed) return;
        if (_mqtt.isConnected) return;

        // Force handshake. This bypasses "isConnected" stale state.
        await _mqtt.updateCredentials(userId: creds.$1, token: creds.$2);

        if (_mqtt.isConnected) return;
      }
    }()
        .whenComplete(() {
      _resumeInFlight = null;
    });

    return _resumeInFlight!;
  }

  // ---------------------------------------------------------------------------
  // Auth-driven credentials updates
  // ---------------------------------------------------------------------------

  /// Called from BlocListener on GlobalAuthCubit changes.
  void _onAuthStateChanged(global_auth.GlobalAuthState _) {
    if (!_ready) return;
    unawaited(_maybeUpdateCredentialsFromAuth());
  }

  (String, String)? _readAuthCredsOrFallback() {
    // Prefer latest creds from auth cubit.
    final auth = context.read<global_auth.GlobalAuthCubit>();
    final userId = auth.getJwtUserData()?.uuid;
    final token = auth.getAccessToken();

    if (userId != null && token != null && userId.isNotEmpty && token.isNotEmpty) {
      return (userId, token);
    }

    // Fallback to creds passed at SessionScope creation.
    if (widget.userId.isNotEmpty && widget.token.isNotEmpty) {
      return (widget.userId, widget.token);
    }

    return null;
  }

  Future<void> _maybeUpdateCredentialsFromAuth() async {
    final creds = _readAuthCredsOrFallback();
    if (creds == null) return;

    final userId = creds.$1;
    final token = creds.$2;

    if (_lastToken == token) return;
    _lastToken = token;

    // Coalesce updates.
    _credsUpdateInFlight ??= _mqtt.updateCredentials(userId: userId, token: token).whenComplete(() {
      _credsUpdateInFlight = null;
    });

    return _credsUpdateInFlight!;
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // ignore: unused_local_variable
    final err = _error;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _home),
        BlocProvider.value(value: _mqtt),
        BlocProvider.value(value: _comm),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AppLifecycleCubit, AppLifecycleStateVm>(
            listenWhen: (p, n) => p.state != n.state,
            listener: (_, life) => _onLifecycle(life),
          ),
          BlocListener<global_auth.GlobalAuthCubit, global_auth.GlobalAuthState>(
            listener: (_, st) => _onAuthStateChanged(st),
          ),
        ],
        child: widget.child,
      ),
    );
  }
}
