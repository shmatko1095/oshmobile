import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';
import 'package:oshmobile/core/network/network_utils/connection_checker.dart';
import 'package:oshmobile/features/startup/domain/contracts/startup_auth_bootstrapper.dart';
import 'package:oshmobile/features/startup/presentation/cubit/startup_cubit.dart';
import 'package:oshmobile/features/startup/presentation/cubit/startup_state.dart';

void main() {
  late _FakeInternetConnectionChecker connectionChecker;
  late _FakeStartupAuthBootstrapper authBootstrapper;
  late _FakeCrashReporterBackend crashReporter;

  setUp(() {
    connectionChecker = _FakeInternetConnectionChecker();
    authBootstrapper = _FakeStartupAuthBootstrapper();
    crashReporter = _FakeCrashReporterBackend();
    OshCrashReporter.debugSetBackend(crashReporter);
  });

  tearDown(() {
    OshCrashReporter.debugResetBackend();
  });

  test('start emits checkingConnectivity then noInternet when offline',
      () async {
    connectionChecker.onCheck = () async => false;
    final cubit = StartupCubit(
      connectionChecker: connectionChecker,
      authBootstrapper: authBootstrapper,
    );

    final emitted = <StartupState>[];
    final sub = cubit.stream.listen(emitted.add);

    await cubit.start();
    await Future<void>.delayed(Duration.zero);

    expect(
      emitted.map((state) => state.stage).toList(),
      <StartupStage>[
        StartupStage.checkingConnectivity,
        StartupStage.noInternet,
      ],
    );
    expect(authBootstrapper.calls, 0);
    expect(
      crashReporter.logs,
      <String>[
        'startup:checking_connectivity',
        'startup:no_internet',
      ],
    );

    await sub.cancel();
    await cubit.close();
  });

  test('start emits restoringSession then ready when online', () async {
    connectionChecker.onCheck = () async => true;
    authBootstrapper.onCheck = () async => true;
    final cubit = StartupCubit(
      connectionChecker: connectionChecker,
      authBootstrapper: authBootstrapper,
    );

    final emitted = <StartupState>[];
    final sub = cubit.stream.listen(emitted.add);

    await cubit.start();
    await Future<void>.delayed(Duration.zero);

    expect(
      emitted.map((state) => state.stage).toList(),
      <StartupStage>[
        StartupStage.checkingConnectivity,
        StartupStage.restoringSession,
        StartupStage.ready,
      ],
    );
    expect(connectionChecker.calls, 1);
    expect(authBootstrapper.calls, 1);
    expect(
      crashReporter.logs,
      <String>[
        'startup:checking_connectivity',
        'startup:restoring_session',
      ],
    );

    await sub.cancel();
    await cubit.close();
  });

  test('retry emits isRetrying before restarting startup flow', () async {
    var isOnline = false;
    connectionChecker.onCheck = () async => isOnline;
    authBootstrapper.onCheck = () async => true;
    final cubit = StartupCubit(
      connectionChecker: connectionChecker,
      authBootstrapper: authBootstrapper,
    );

    final emitted = <StartupState>[];
    final sub = cubit.stream.listen(emitted.add);

    await cubit.start();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.stage, StartupStage.noInternet);

    isOnline = true;
    await cubit.retry();
    await Future<void>.delayed(Duration.zero);

    expect(
      emitted.any(
        (state) => state.stage == StartupStage.noInternet && state.isRetrying,
      ),
      isTrue,
    );
    expect(cubit.state.stage, StartupStage.ready);
    expect(
      crashReporter.logs,
      containsAllInOrder(<String>[
        'startup:no_internet',
        'startup:retry',
        'startup:checking_connectivity',
        'startup:restoring_session',
      ]),
    );

    await sub.cancel();
    await cubit.close();
  });

  test('start and retry share one in-flight bootstrap run', () async {
    connectionChecker.onCheck = () async => true;
    final completer = Completer<bool>();
    authBootstrapper.onCheck = () => completer.future;
    final cubit = StartupCubit(
      connectionChecker: connectionChecker,
      authBootstrapper: authBootstrapper,
    );

    final future1 = cubit.start();
    final future2 = cubit.start();
    final future3 = cubit.retry();
    await Future<void>.delayed(Duration.zero);

    expect(identical(future1, future2), isTrue);
    expect(identical(future1, future3), isTrue);
    expect(connectionChecker.calls, 1);
    expect(authBootstrapper.calls, 1);

    completer.complete(true);
    await Future.wait<void>(<Future<void>>[future1, future2, future3]);

    expect(cubit.state.stage, StartupStage.ready);
    await cubit.close();
  });

  test(
      'unexpected connectivity exception is logged once and falls back to noInternet',
      () async {
    connectionChecker.onCheck =
        () async => throw StateError('network probe failed');
    final cubit = StartupCubit(
      connectionChecker: connectionChecker,
      authBootstrapper: authBootstrapper,
    );

    await cubit.start();
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.stage, StartupStage.noInternet);
    expect(crashReporter.recordedErrors, hasLength(1));
    expect(
        crashReporter.recordedErrors.single.reason, 'Startup bootstrap failed');
    expect(crashReporter.customKeys['phase'], 'checking_connectivity');
    expect(crashReporter.customKeys['is_retry'], isFalse);

    await cubit.close();
  });
}

class _FakeInternetConnectionChecker implements InternetConnectionChecker {
  int calls = 0;
  Future<bool> Function()? onCheck;

  @override
  Future<bool> get isConnected async {
    calls++;
    return onCheck?.call() ?? true;
  }
}

class _FakeStartupAuthBootstrapper implements StartupAuthBootstrapper {
  int calls = 0;
  Future<bool> Function()? onCheck;

  @override
  Future<bool> checkAuthStatus() {
    calls++;
    return onCheck?.call() ?? Future<bool>.value(true);
  }
}

class _RecordedError {
  const _RecordedError({
    required this.error,
    required this.stackTrace,
    required this.fatal,
    required this.reason,
  });

  final Object error;
  final StackTrace? stackTrace;
  final bool fatal;
  final String? reason;
}

class _FakeCrashReporterBackend implements CrashReporterBackend {
  final List<String> logs = <String>[];
  final List<_RecordedError> recordedErrors = <_RecordedError>[];
  final Map<String, Object> customKeys = <String, Object>{};

  @override
  void log(String message) {
    logs.add(message);
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    required bool fatal,
    String? reason,
  }) async {
    recordedErrors.add(
      _RecordedError(
        error: error,
        stackTrace: stack,
        fatal: fatal,
        reason: reason,
      ),
    );
  }

  @override
  Future<void> recordFlutterFatalError(FlutterErrorDetails details) async {}

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setCustomKey(String key, Object value) async {
    customKeys[key] = value;
  }

  @override
  Future<void> setUserId(String userId) async {}
}
