import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';
import 'package:oshmobile/core/network/network_utils/connection_checker.dart';
import 'package:oshmobile/features/startup/domain/contracts/startup_auth_bootstrapper.dart';
import 'package:oshmobile/features/startup/presentation/cubit/startup_state.dart';

class StartupCubit extends Cubit<StartupState> {
  StartupCubit({
    required InternetConnectionChecker connectionChecker,
    required StartupAuthBootstrapper authBootstrapper,
  })  : _connectionChecker = connectionChecker,
        _authBootstrapper = authBootstrapper,
        super(const StartupState());

  final InternetConnectionChecker _connectionChecker;
  final StartupAuthBootstrapper _authBootstrapper;

  Future<void>? _inFlight;

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

    emit(const StartupState(stage: StartupStage.checkingConnectivity));
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

    emit(const StartupState(stage: StartupStage.restoringSession));
    OshCrashReporter.log('startup:restoring_session');

    try {
      await _authBootstrapper.checkAuthStatus();
    } catch (error, st) {
      await _reportStartupFailure(
        error,
        st,
        phase: 'restoring_session',
        isRetry: isRetry,
      );
    }

    emit(const StartupState(stage: StartupStage.ready));
  }

  void _emitNoInternet() {
    emit(const StartupState(stage: StartupStage.noInternet));
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
