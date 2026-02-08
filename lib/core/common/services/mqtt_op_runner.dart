import 'dart:async';

import 'package:oshmobile/core/common/cubits/mqtt/mqtt_comm_cubit.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';
import 'package:oshmobile/core/utils/serial_executor.dart';
import 'package:oshmobile/core/utils/superseded_exception.dart';

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
    return serial.run(() => _runInternal(
          reqId: reqId,
          op: op,
          timeoutReason: timeoutReason,
          errorReason: errorReason,
          extraContext: extraContext,
          timeoutCommMessage: timeoutCommMessage,
          errorCommMessage: errorCommMessage,
          onSuccess: onSuccess,
          onTimeout: onTimeout,
          onError: onError,
          onFinally: onFinally,
        ));
  }

  Future<void> runUnserialized({
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
    return _runInternal(
      reqId: reqId,
      op: op,
      timeoutReason: timeoutReason,
      errorReason: errorReason,
      extraContext: extraContext,
      timeoutCommMessage: timeoutCommMessage,
      errorCommMessage: errorCommMessage,
      onSuccess: onSuccess,
      onTimeout: onTimeout,
      onError: onError,
      onFinally: onFinally,
    );
  }

  Future<void> _runInternal({
    required String reqId,
    required Future<void> Function() op,
    required String timeoutReason,
    required String errorReason,
    required Map<String, Object?> extraContext,
    required String timeoutCommMessage,
    required String Function(Object error)? errorCommMessage,
    required void Function() onSuccess,
    required void Function() onTimeout,
    required void Function(Object error) onError,
    void Function()? onFinally,
  }) async {
    try {
      await op();
      comm.complete(reqId);
      onSuccess();
    } on SupersededException {
      comm.complete(reqId);
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
  }
}
