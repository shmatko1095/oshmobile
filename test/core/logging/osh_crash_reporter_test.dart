import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';

void main() {
  late _ThrowingCrashReporterBackend backend;

  setUp(() {
    backend = _ThrowingCrashReporterBackend();
    OshCrashReporter.debugSetBackend(backend);
  });

  tearDown(OshCrashReporter.debugResetBackend);

  test('logFatal swallows backend failures', () async {
    await expectLater(
      OshCrashReporter.logFatal(
        StateError('app failure'),
        StackTrace.current,
        reason: 'test fatal',
      ),
      completes,
    );

    expect(backend.recordErrorCalls, 1);
  });

  test('logFlutterFatalError swallows backend failures', () async {
    final details = FlutterErrorDetails(
      exception: StateError('framework failure'),
      stack: StackTrace.current,
    );

    await expectLater(
      OshCrashReporter.logFlutterFatalError(details),
      completes,
    );

    expect(backend.recordFlutterFatalErrorCalls, 1);
  });
}

final class _ThrowingCrashReporterBackend implements CrashReporterBackend {
  int recordErrorCalls = 0;
  int recordFlutterFatalErrorCalls = 0;

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    required bool fatal,
    String? reason,
  }) {
    recordErrorCalls++;
    throw TimeoutException('Timeout waiting for settings get response');
  }

  @override
  Future<void> recordFlutterFatalError(FlutterErrorDetails details) {
    recordFlutterFatalErrorCalls++;
    throw TimeoutException('Timeout waiting for settings get response');
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setCustomKey(String key, Object value) async {}

  @override
  Future<void> setUserId(String userId) async {}

  @override
  void log(String message) {}
}
