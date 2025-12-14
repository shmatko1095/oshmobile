import 'dart:async';

import 'package:oshmobile/core/common/cubits/mqtt/mqtt_comm_cubit.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';
import 'package:oshmobile/core/utils/serial_executor.dart';

/// Runs a single MQTT operation with:
/// - serial execution (no overlap)
/// - unified timeout/error handling
/// - comm.complete/comm.fail
///
/// NOTE: comm.start(reqId, deviceSn) should be called by the caller BEFORE run(),
/// so UI can react immediately.
class MqttOpRunner {
  final String deviceSn;
  final SerialExecutor serial;
  final MqttCommCubit comm;

  const MqttOpRunner({
    required this.deviceSn,
    required this.serial,
    required this.comm,
  });

  Future<void> run({
    required String reqId,
    required Future<void> Function() op,
    required String timeoutReason,
    required String errorReason,
    Map<String, Object?> extraContext = const {},
    String timeoutCommMessage = 'Operation timed out',
    String Function(Object error)? errorCommMessage,
    required void Function() onSuccess,
    required void Function() onTimeout,
    required void Function(Object error) onError,
    void Function()? onFinally,
  }) {
    return serial.run(() async {
      try {
        await op();
        comm.complete(reqId);
        onSuccess();
      } on TimeoutException catch (e, stack) {
        OshCrashReporter.logNonFatal(
          e,
          stack,
          reason: timeoutReason,
          context: {
            'deviceSn': deviceSn,
            'reqId': reqId,
            ...extraContext,
          },
        );
        comm.fail(reqId, timeoutCommMessage);
        onTimeout();
      } catch (e, stack) {
        OshCrashReporter.logNonFatal(
          e,
          stack,
          reason: errorReason,
          context: {
            'deviceSn': deviceSn,
            'reqId': reqId,
            ...extraContext,
          },
        );
        comm.fail(reqId, (errorCommMessage ?? (_) => 'Operation failed')(e));
        onError(e);
      } finally {
        onFinally?.call();
      }
    });
  }
}
