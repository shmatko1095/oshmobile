import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/analytics/osh_analytics.dart';
import 'package:oshmobile/core/analytics/osh_analytics_events.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';
import 'package:oshmobile/core/network/network_utils/connection_checker.dart';
import 'package:oshmobile/features/startup/domain/contracts/startup_auth_bootstrapper.dart';
import 'package:oshmobile/features/startup/domain/models/mobile_client_policy_decision.dart';
import 'package:oshmobile/features/startup/domain/models/mobile_client_policy_status.dart';
import 'package:oshmobile/features/startup/domain/repositories/startup_client_policy_repository.dart';
import 'package:oshmobile/features/startup/presentation/cubit/startup_state.dart';

class StartupCubit extends Cubit<StartupState> {
  StartupCubit({
    required InternetConnectionChecker connectionChecker,
    required StartupAuthBootstrapper authBootstrapper,
    required StartupClientPolicyRepository clientPolicyRepository,
  })  : _connectionChecker = connectionChecker,
        _authBootstrapper = authBootstrapper,
        _clientPolicyRepository = clientPolicyRepository,
        super(const StartupState());

  static const String _sourceStartup = 'startup';
  static const String _sourceResume = 'resume';

  final InternetConnectionChecker _connectionChecker;
  final StartupAuthBootstrapper _authBootstrapper;
  final StartupClientPolicyRepository _clientPolicyRepository;

  Future<void>? _inFlight;
  Future<MobileClientPolicyDecision>? _policyCheckInFlight;

  String? get currentStoreUrl => state.policy?.storeUrl;

  Future<void> start() {
    if (state.stage == StartupStage.ready) {
      return Future<void>.value();
    }
    return _run(isRetry: false);
  }

  Future<void> retry() {
    if (state.stage != StartupStage.noInternet) {
      return _inFlight ?? Future<void>.value();
    }
    return _run(isRetry: true);
  }

  Future<void> onAppResumed() {
    return _runBackgroundPolicyCheck(source: _sourceResume);
  }

  Future<void> onRecommendLaterTapped() async {
    final policy = state.policy;
    if (policy == null) {
      emit(state.copyWith(pendingRecommendPrompt: false));
      return;
    }

    await _clientPolicyRepository.suppressRecommendPrompt(
      policyVersion: policy.policyVersion,
    );

    await OshAnalytics.logEvent(
      OshAnalyticsEvents.mobilePolicyLaterTapped,
      parameters: {
        'policy_version': policy.policyVersion,
      },
    );

    emit(state.copyWith(pendingRecommendPrompt: false));
  }

  Future<void> onRecommendPromptDismissed() async {
    if (!state.pendingRecommendPrompt) {
      return;
    }
    emit(state.copyWith(pendingRecommendPrompt: false));
  }

  Future<void> onUpdateNowTapped({required String source}) {
    return OshAnalytics.logEvent(
      OshAnalyticsEvents.mobilePolicyUpdateTapped,
      parameters: {
        'source': source,
        'status': state.policyStatus?.wireValue,
        'policy_version': state.policy?.policyVersion,
      },
    );
  }

  Future<void> _run({required bool isRetry}) {
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;

    final future = _runInternal(isRetry: isRetry);
    _inFlight = future;
    future.whenComplete(() {
      if (identical(_inFlight, future)) {
        _inFlight = null;
      }
    });
    return future;
  }

  Future<void> _runInternal({required bool isRetry}) async {
    if (isRetry) {
      OshCrashReporter.log('startup:retry');
      emit(state.copyWith(isRetrying: true));
    }

    emit(state.copyWith(
      stage: StartupStage.checkingConnectivity,
      isRetrying: false,
    ));
    OshCrashReporter.log('startup:checking_connectivity');

    final bool isConnected;
    try {
      isConnected = await _connectionChecker.isConnected;
    } catch (error, st) {
      await _reportStartupFailure(
        error,
        st,
        phase: 'checking_connectivity',
        isRetry: isRetry,
      );
      _emitNoInternet();
      return;
    }

    if (!isConnected) {
      _emitNoInternet();
      return;
    }

    emit(state.copyWith(stage: StartupStage.restoringSession));
    OshCrashReporter.log('startup:restoring_session');

    final StartupAuthBootstrapResult authResult;
    try {
      authResult = await _authBootstrapper.checkAuthStatus();
    } catch (error, st) {
      await _reportStartupFailure(
        error,
        st,
        phase: 'restoring_session',
        isRetry: isRetry,
      );
      _emitNoInternet();
      return;
    }

    if (authResult == StartupAuthBootstrapResult.transientFailure) {
      _emitNoInternet();
      return;
    }

    emit(state.copyWith(stage: StartupStage.ready));

    unawaited(_runBackgroundPolicyCheck(source: _sourceStartup));
  }

  Future<void> _runBackgroundPolicyCheck({required String source}) {
    if (state.stage != StartupStage.ready) {
      return Future<void>.value();
    }

    if (state.isPolicyCheckInProgress) {
      final inFlight = _policyCheckInFlight;
      if (inFlight != null) {
        return inFlight.then((_) {});
      }
      return Future<void>.value();
    }

    return _runPolicyCheck(source: source);
  }

  Future<void> _runPolicyCheck({required String source}) async {
    emit(state.copyWith(isPolicyCheckInProgress: true));
    OshCrashReporter.log(
      source == _sourceStartup
          ? 'startup:checking_client_policy'
          : 'startup:checking_client_policy_resume',
    );

    try {
      final decision = await _safeCheckPolicy(
        source: source,
        isRetry: false,
      );
      if (decision == null) {
        return;
      }

      _applyPolicyDecision(decision);

      if (decision.shouldShowRecommendPrompt && !state.hardUpdateRequired) {
        _queueRecommendPrompt();
      }
    } finally {
      emit(state.copyWith(isPolicyCheckInProgress: false));
    }
  }

  Future<MobileClientPolicyDecision?> _safeCheckPolicy({
    required String source,
    required bool isRetry,
  }) async {
    try {
      final decision = await _checkPolicy();
      await _logPolicyDecision(decision, source: source);
      return decision;
    } catch (error, st) {
      await _reportStartupFailure(
        error,
        st,
        phase: 'checking_client_policy',
        isRetry: isRetry,
      );
      return null;
    }
  }

  Future<MobileClientPolicyDecision> _checkPolicy() {
    final inFlight = _policyCheckInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final future = _clientPolicyRepository.checkPolicy();
    _policyCheckInFlight = future;
    future.whenComplete(() {
      if (identical(_policyCheckInFlight, future)) {
        _policyCheckInFlight = null;
      }
    });
    return future;
  }

  void _applyPolicyDecision(MobileClientPolicyDecision decision) {
    final wasHardUpdateRequired = state.hardUpdateRequired;
    final isHardUpdateRequired =
        decision.status == MobileClientPolicyStatus.requireUpdate;

    emit(state.copyWith(
      policy: decision.policy,
      clearPolicy: decision.policy == null,
      policyStatus: decision.status,
      hardUpdateRequired: isHardUpdateRequired,
      pendingRecommendPrompt: false,
    ));

    if (!wasHardUpdateRequired && isHardUpdateRequired) {
      unawaited(
        OshAnalytics.logEvent(
          OshAnalyticsEvents.mobilePolicyPromptShown,
          parameters: {
            'status': MobileClientPolicyStatus.requireUpdate.wireValue,
            'policy_version': decision.policy?.policyVersion,
          },
        ),
      );
    }
  }

  void _queueRecommendPrompt() {
    if (state.pendingRecommendPrompt || state.hardUpdateRequired) {
      return;
    }

    final requestId = state.recommendPromptRequestId + 1;
    emit(state.copyWith(
      pendingRecommendPrompt: true,
      recommendPromptRequestId: requestId,
    ));

    unawaited(
      OshAnalytics.logEvent(
        OshAnalyticsEvents.mobilePolicyPromptShown,
        parameters: {
          'status': MobileClientPolicyStatus.recommendUpdate.wireValue,
          'policy_version': state.policy?.policyVersion,
        },
      ),
    );
  }

  Future<void> _logPolicyDecision(
    MobileClientPolicyDecision decision, {
    required String source,
  }) async {
    await OshAnalytics.logEvent(
      OshAnalyticsEvents.mobilePolicyFetched,
      parameters: {
        'source': source,
        'status': decision.status.wireValue,
        'policy_version': decision.policy?.policyVersion,
        'from_cache': decision.fromCache,
        'fail_open': decision.failOpen,
        'http_status': decision.httpStatus,
      },
    );

    if (decision.fromCache) {
      await OshAnalytics.logEvent(
        OshAnalyticsEvents.mobilePolicyFallbackCache,
        parameters: {
          'source': source,
          'status': decision.status.wireValue,
          'policy_version': decision.policy?.policyVersion,
          'http_status': decision.httpStatus,
        },
      );
    }

    if (decision.failOpen) {
      await OshAnalytics.logEvent(
        OshAnalyticsEvents.mobilePolicyFailOpen,
        parameters: {
          'source': source,
          'http_status': decision.httpStatus,
        },
      );
    }
  }

  void _emitNoInternet() {
    emit(state.copyWith(stage: StartupStage.noInternet));
    OshCrashReporter.log('startup:no_internet');
  }

  Future<void> _reportStartupFailure(
    Object error,
    StackTrace? stackTrace, {
    required String phase,
    required bool isRetry,
  }) {
    return OshCrashReporter.logNonFatal(
      error,
      stackTrace,
      reason: 'Startup bootstrap failed',
      context: <String, Object?>{
        'phase': phase,
        'is_retry': isRetry,
      },
    );
  }
}
