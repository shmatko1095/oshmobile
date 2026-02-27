import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:oshmobile/app/session/di/session_di.dart';
import 'package:oshmobile/core/common/cubits/mqtt/global_mqtt_cubit.dart';
import 'package:oshmobile/core/common/cubits/mqtt/mqtt_comm_cubit.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';

/// Owns MQTT connect/disconnect/credential refresh for one authenticated session.
class MqttSessionController {
  final SessionCredentials creds;
  final GlobalMqttCubit mqtt;
  final MqttCommCubit comm;

  late final Future<void> ready;

  Future<void>? _disconnectInFlight;
  Future<void>? _resumeInFlight;
  Future<void>? _credsUpdateInFlight;
  bool _credsSyncQueued = false;

  late String _activeUserId = creds.userId;
  late String _activeToken = creds.token;

  AppLifecycleState? _lastLifecycle;

  MqttSessionController({
    required this.creds,
    required this.mqtt,
    required this.comm,
  }) {
    ready = _connect();
  }

  Future<void> _connect() async {
    try {
      await mqtt.connectWith(userId: _activeUserId, token: _activeToken);
    } catch (e, st) {
      await OshCrashReporter.logNonFatal(
        e,
        st,
        reason: 'MQTT connect failed in session',
      );
      rethrow;
    }
  }

  Future<void> dispose() async {
    comm.reset();
    await disconnect();
  }

  Future<void> disconnect() {
    return _disconnectInFlight ??= () async {
      _credsSyncQueued = false;

      final credsInFlight = _credsUpdateInFlight;
      if (credsInFlight != null) {
        try {
          await credsInFlight;
        } catch (_) {}
      }

      await mqtt.disconnect();
    }()
        .whenComplete(() {
      _disconnectInFlight = null;
    });
  }

  Future<void> resume() async {
    _resumeInFlight ??= () async {
      if (_disconnectInFlight != null) {
        try {
          await _disconnectInFlight;
        } catch (_) {}
      }

      final delays = <Duration>[
        Duration.zero,
        const Duration(seconds: 1),
        const Duration(seconds: 2),
        const Duration(seconds: 4),
      ];

      for (final delay in delays) {
        if (_lastLifecycle != AppLifecycleState.resumed) return;

        if (delay > Duration.zero) {
          await Future.delayed(delay);
        }
        if (_lastLifecycle != AppLifecycleState.resumed) return;
        if (mqtt.isConnected) return;

        if (_credsSyncQueued || _credsUpdateInFlight != null) {
          await _syncCredentialsNow();
        } else {
          await mqtt.updateCredentials(
            userId: _activeUserId,
            token: _activeToken,
          );
        }

        if (mqtt.isConnected) return;
      }
    }()
        .whenComplete(() {
      _resumeInFlight = null;
    });

    return _resumeInFlight!;
  }

  Future<void> updateCredentials({
    required String userId,
    required String token,
  }) {
    final changed = userId != _activeUserId || token != _activeToken;
    _activeUserId = userId;
    _activeToken = token;

    if (!changed) {
      return Future<void>.value();
    }

    _credsSyncQueued = true;
    if (!_canReconnectNow) {
      // Defer reconnect until app is resumed.
      return Future<void>.value();
    }

    return _syncCredentialsNow();
  }

  bool get _canReconnectNow {
    final life = _lastLifecycle;
    if (life == null) return true;
    return life == AppLifecycleState.resumed;
  }

  Future<void> _syncCredentialsNow() {
    final inFlight = _credsUpdateInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    _credsUpdateInFlight = () async {
      while (_credsSyncQueued) {
        if (!_canReconnectNow) return;
        _credsSyncQueued = false;
        await mqtt.updateCredentials(
          userId: _activeUserId,
          token: _activeToken,
        );
      }
    }()
        .whenComplete(() {
      _credsUpdateInFlight = null;
    });

    return _credsUpdateInFlight!;
  }

  Future<void> onAppLifecycle(AppLifecycleState state) async {
    if (_lastLifecycle == state) return;
    _lastLifecycle = state;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      await disconnect();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      await resume();
    }
  }
}
