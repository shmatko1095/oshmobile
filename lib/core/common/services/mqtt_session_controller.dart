import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:oshmobile/core/common/cubits/mqtt/global_mqtt_cubit.dart';
import 'package:oshmobile/core/common/cubits/mqtt/mqtt_comm_cubit.dart';
import 'package:oshmobile/core/di/session_di.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';

/// Owns MQTT connect/disconnect for the whole authenticated session.
/// No UI calls connect(): UI only waits `ready`.
class MqttSessionController {
  final SessionCredentials creds;
  final GlobalMqttCubit mqtt;
  final MqttCommCubit comm;

  late final Future<void> ready;

  Future<void>? _resumeInFlight;
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
      await mqtt.connectWith(userId: creds.userId, token: creds.token);
    } catch (e, st) {
      // Keep session alive even if MQTT failed; UI can show error state from mqtt cubit.
      await OshCrashReporter.logNonFatal(e, st, reason: 'MQTT connect failed in session');
      rethrow;
    }
  }

  Future<void> dispose() async {
    comm.reset();
    await mqtt.disconnect();
  }

  /// Called from SessionScope when the app goes to background / foreground.
  ///
  /// Goals:
  /// - On background: disconnect cleanly to avoid OS aborting the socket.
  /// - On resume: reconnect (best-effort) so feature cubits can publish immediately.
  Future<void> onAppLifecycle(AppLifecycleState state) async {
    if (_lastLifecycle == state) return;
    _lastLifecycle = state;

    // We only care about stable states. Inactive can happen during transitions.
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      try {
        await mqtt.disconnect();
      } catch (e, st) {
        await OshCrashReporter.logNonFatal(e, st, reason: 'MQTT disconnect failed on background');
      }
      return;
    }

    if (state == AppLifecycleState.resumed) {
      // Coalesce multiple resume events.
      _resumeInFlight ??= () async {
        try {
          await mqtt.connectWith(userId: creds.userId, token: creds.token);
        } catch (e, st) {
          // Best-effort; keep session alive.
          await OshCrashReporter.logNonFatal(e, st, reason: 'MQTT reconnect failed on resume');
        }
      }();

      try {
        await _resumeInFlight;
      } finally {
        _resumeInFlight = null;
      }
    }
  }
}
