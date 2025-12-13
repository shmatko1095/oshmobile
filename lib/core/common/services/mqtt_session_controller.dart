import 'dart:async';

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

  MqttSessionController({
    required this.creds,
    required this.mqtt,
    required this.comm,
  }) {
    // Start connect immediately when session scope is created.
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
    // Clear comm state FIRST (while cubit is still alive).
    comm.reset();

    // Then disconnect transport via global cubit.
    await mqtt.disconnect();
  }
}
