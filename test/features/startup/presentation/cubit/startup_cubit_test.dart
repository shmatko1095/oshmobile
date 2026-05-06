import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/analytics/osh_analytics.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';
import 'package:oshmobile/core/network/network_utils/connection_checker.dart';
import 'package:oshmobile/features/startup/domain/contracts/startup_auth_bootstrapper.dart';
import 'package:oshmobile/features/startup/domain/models/mobile_client_policy.dart';
import 'package:oshmobile/features/startup/domain/models/mobile_client_policy_decision.dart';
import 'package:oshmobile/features/startup/domain/models/mobile_client_policy_status.dart';
import 'package:oshmobile/features/startup/domain/repositories/startup_client_policy_repository.dart';
import 'package:oshmobile/features/startup/presentation/cubit/startup_cubit.dart';
import 'package:oshmobile/features/startup/presentation/cubit/startup_state.dart';

void main() {
  late _FakeInternetConnectionChecker connectionChecker;
  late _FakeStartupAuthBootstrapper authBootstrapper;
  late _FakeStartupClientPolicyRepository policyRepository;
  late _FakeCrashReporterBackend crashReporter;

  setUp(() {
    connectionChecker = _FakeInternetConnectionChecker();
    authBootstrapper = _FakeStartupAuthBootstrapper();
    policyRepository = _FakeStartupClientPolicyRepository();
    crashReporter = _FakeCrashReporterBackend();

    OshCrashReporter.debugSetBackend(crashReporter);
    OshAnalytics.debugSetBackend(const _NoopAnalyticsBackend());
  });

  tearDown(() {
    OshCrashReporter.debugResetBackend();
    OshAnalytics.debugResetBackend();
  });

  test('start emits checkingConnectivity then noInternet when offline',
      () async {
    connectionChecker.onCheck = () async => false;
    final cubit = StartupCubit(
      connectionChecker: connectionChecker,
      authBootstrapper: authBootstrapper,
      clientPolicyRepository: policyRepository,
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
    expect(policyRepository.calls, 0);
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

  test('start reaches ready before background policy result is applied',
      () async {
    connectionChecker.onCheck = () async => true;
    authBootstrapper.onCheck = () async => true;
    final policyCompleter = Completer<MobileClientPolicyDecision>();
    policyRepository.onCheck = () => policyCompleter.future;

    final cubit = StartupCubit(
      connectionChecker: connectionChecker,
      authBootstrapper: authBootstrapper,
      clientPolicyRepository: policyRepository,
    );

    final emitted = <StartupState>[];
    final sub = cubit.stream.listen(emitted.add);

    await cubit.start();
    await Future<void>.delayed(Duration.zero);

    expect(
      emitted.map((state) => state.stage).take(3).toList(),
      <StartupStage>[
        StartupStage.checkingConnectivity,
        StartupStage.restoringSession,
        StartupStage.ready,
      ],
    );
    expect(connectionChecker.calls, 1);
    expect(policyRepository.calls, 1);
    expect(authBootstrapper.calls, 1);
    expect(cubit.state.stage, StartupStage.ready);
    expect(cubit.state.isPolicyCheckInProgress, isTrue);
    expect(cubit.state.policyStatus, isNull);

    policyCompleter.complete(_allowDecision);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.isPolicyCheckInProgress, isFalse);
    expect(cubit.state.policyStatus, MobileClientPolicyStatus.allow);
    expect(
      crashReporter.logs,
      containsAllInOrder(<String>[
        'startup:checking_connectivity',
        'startup:restoring_session',
        'startup:checking_client_policy',
      ]),
    );

    await sub.cancel();
    await cubit.close();
  });

  test('require_update is applied after startup reaches ready', () async {
    connectionChecker.onCheck = () async => true;
    authBootstrapper.onCheck = () async => true;
    policyRepository.nextDecision = MobileClientPolicyDecision(
      status: MobileClientPolicyStatus.requireUpdate,
      policy: _samplePolicy,
    );

    final cubit = StartupCubit(
      connectionChecker: connectionChecker,
      authBootstrapper: authBootstrapper,
      clientPolicyRepository: policyRepository,
    );

    await cubit.start();
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.stage, StartupStage.ready);
    expect(cubit.state.hardUpdateRequired, isTrue);
    expect(cubit.state.policyStatus, MobileClientPolicyStatus.requireUpdate);
    expect(authBootstrapper.calls, 1);

    await cubit.close();
  });

  test('retry emits isRetrying before restarting startup flow', () async {
    var isOnline = false;
    connectionChecker.onCheck = () async => isOnline;
    authBootstrapper.onCheck = () async => true;
    policyRepository.nextDecision = _allowDecision;

    final cubit = StartupCubit(
      connectionChecker: connectionChecker,
      authBootstrapper: authBootstrapper,
      clientPolicyRepository: policyRepository,
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

    await sub.cancel();
    await cubit.close();
  });

  test('onAppResumed applies require_update immediately', () async {
    connectionChecker.onCheck = () async => true;
    authBootstrapper.onCheck = () async => true;
    policyRepository.nextDecision = _allowDecision;

    final cubit = StartupCubit(
      connectionChecker: connectionChecker,
      authBootstrapper: authBootstrapper,
      clientPolicyRepository: policyRepository,
    );

    await cubit.start();
    await Future<void>.delayed(Duration.zero);

    policyRepository.nextDecision = MobileClientPolicyDecision(
      status: MobileClientPolicyStatus.requireUpdate,
      policy: _samplePolicy,
    );

    await cubit.onAppResumed();

    expect(cubit.state.hardUpdateRequired, isTrue);

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
      clientPolicyRepository: policyRepository,
    );

    await cubit.start();
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.stage, StartupStage.noInternet);
    expect(crashReporter.recordedErrors, hasLength(1));
    expect(
      crashReporter.recordedErrors.single.reason,
      'Startup bootstrap failed',
    );
    expect(crashReporter.customKeys['phase'], 'checking_connectivity');
    expect(crashReporter.customKeys['is_retry'], isFalse);

    await cubit.close();
  });
}

final MobileClientPolicy _samplePolicy = MobileClientPolicy(
  minSupportedVersion: '1.0.0',
  latestVersion: '2.0.0',
  storeUrl: 'https://example.com/store',
  policyVersion: 12,
  checkedAt: DateTime.utc(2026, 4, 16, 12),
  fetchedAt: DateTime.utc(2026, 4, 16, 12),
);

const MobileClientPolicyDecision _allowDecision = MobileClientPolicyDecision(
  status: MobileClientPolicyStatus.allow,
);

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

class _FakeStartupClientPolicyRepository
    implements StartupClientPolicyRepository {
  int calls = 0;
  MobileClientPolicyDecision nextDecision = _allowDecision;
  Future<MobileClientPolicyDecision> Function()? onCheck;

  @override
  Future<MobileClientPolicyDecision> checkPolicy() async {
    calls++;
    final onCheck = this.onCheck;
    if (onCheck != null) {
      return onCheck();
    }
    return nextDecision;
  }

  @override
  Future<void> suppressRecommendPrompt({required int policyVersion}) async {}
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

class _NoopAnalyticsBackend implements AnalyticsBackend {
  const _NoopAnalyticsBackend();

  @override
  Future<void> logEvent(
    String name, {
    Map<String, Object?>? parameters,
  }) async {}

  @override
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
    Map<String, Object?>? parameters,
  }) async {}

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setUserId(String? userId) async {}

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {}
}
