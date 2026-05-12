import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:keycloak_wrapper/keycloak_wrapper.dart';
import 'package:oshmobile/core/analytics/osh_analytics.dart';
import 'package:oshmobile/core/analytics/osh_analytics_events.dart';
import 'package:oshmobile/core/analytics/osh_analytics_user_properties.dart';
import 'package:oshmobile/core/common/entities/jwt_user_data.dart';
import 'package:oshmobile/core/common/entities/session.dart';
import 'package:oshmobile/core/common/cubits/auth/session_provisioning_failure.dart';
import 'package:oshmobile/core/logging/app_log.dart';
import 'package:oshmobile/core/logging/crashlytics_context_keys.dart';
import 'package:oshmobile/core/logging/crashlytics_context_sync.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';
import 'package:oshmobile/core/network/chopper_client/auth/auth_service.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_service.dart';
import 'package:oshmobile/core/network/chopper_client/core/session_storage.dart';
import 'package:oshmobile/core/network/rest_response_error_mapper.dart';
import 'package:oshmobile/features/startup/domain/contracts/startup_auth_bootstrapper.dart';

part 'global_auth_state.dart';

class GlobalAuthCubit extends Cubit<GlobalAuthState>
    implements StartupAuthBootstrapper {
  final AuthService _authService;
  final MobileV1Service _mobileService;
  final SessionStorage _sessionStorage;
  final KeycloakWrapper _keycloakWrapper;

  GlobalAuthCubit({
    required AuthService authService,
    required MobileV1Service mobileService,
    required SessionStorage sessionStorage,
    required KeycloakWrapper keycloakWrapper,
  })  : _authService = authService,
        _mobileService = mobileService,
        _sessionStorage = sessionStorage,
        _keycloakWrapper = keycloakWrapper,
        super(const AuthInitial(0));

  int _revision = 0;
  Future<StartupAuthBootstrapResult>? _authBootstrapFuture;

  void _emitAuthInitial() {
    _revision++;
    emit(AuthInitial(_revision));
  }

  void _emitAuthenticated() {
    _revision++;
    emit(AuthAuthenticated(_revision));
  }

  @override
  Future<StartupAuthBootstrapResult> checkAuthStatus() {
    final inFlight = _authBootstrapFuture;
    if (inFlight != null) return inFlight;

    final future = _bootstrapStoredSession();
    _authBootstrapFuture = future;
    future.whenComplete(() {
      if (identical(_authBootstrapFuture, future)) {
        _authBootstrapFuture = null;
      }
    });
    return future;
  }

  Future<void> signedIn(Session session) async {
    await _sessionStorage.setSession(session);
    if (!session.isDemoMode) {
      try {
        await _ensureStoredSession();
      } on SessionProvisioningException catch (error) {
        if (error.kind == SessionProvisioningFailureKind.authRejected) {
          await _rejectStoredSession();
        }
        rethrow;
      }
    }
    await _syncTelemetryIdentity();
    _emitAuthenticated();
  }

  Future<void> signedOut() async {
    final shouldLogoutKeycloak = !isDemoMode && _isLoggedInWithKeycloak;
    if (shouldLogoutKeycloak) {
      try {
        await _keycloakWrapper.logout();
      } catch (e) {
        AppLog.warn('Keycloak logout failed: $e');
      }
    }

    await _sessionStorage.clearSession();
    await OshAnalytics.logEvent(OshAnalyticsEvents.authSignedOut);
    await _clearTelemetryIdentity();
    _emitAuthInitial();
  }

  Future<bool> refreshToken() async {
    return await _refreshTokenInternal() ?? false;
  }

  Future<StartupAuthBootstrapResult> _bootstrapStoredSession() async {
    final refreshed = await _refreshTokenInternal(ensureProvisioning: true);
    if (refreshed == null) {
      return StartupAuthBootstrapResult.transientFailure;
    }
    return refreshed
        ? StartupAuthBootstrapResult.authenticated
        : StartupAuthBootstrapResult.unauthenticated;
  }

  Future<bool?> _refreshTokenInternal({bool ensureProvisioning = false}) async {
    try {
      final currentSession = _sessionStorage.getSession();
      if (currentSession == null) {
        await _clearTelemetryIdentity();
        _emitAuthInitial();
        return false;
      }

      if (currentSession.isDemoMode) {
        return await _refreshDemoSession();
      }

      final response = await _authService.refreshToken(
        refreshToken: currentSession.refreshToken,
      );

      if (!response.isSuccessful || response.body == null) {
        await _clearTelemetryIdentity();
        _emitAuthInitial();
        AppLog.warn('Refresh token request failed: ${response.bodyString}');
        return false;
      }

      final session = Session.fromJson(response.body).copyWith(
        authProvider: currentSession.authProvider,
      );
      await _sessionStorage.setSession(session);
      if (ensureProvisioning) {
        try {
          await _ensureStoredSession();
        } on SessionProvisioningException catch (error, st) {
          if (error.kind == SessionProvisioningFailureKind.transient) {
            OshCrashReporter.logNonFatal(
              error,
              st,
              reason: 'Session provisioning failed during startup',
            );
            return null;
          }
          await _rejectStoredSession();
          return false;
        }
      }
      await _syncTelemetryIdentity();
      _emitAuthenticated();
      return true;
    } catch (error, st) {
      OshCrashReporter.logNonFatal(error, st, reason: 'Token refresh failed');
      await _clearTelemetryIdentity();
      _emitAuthInitial();
      return false;
    }
  }

  String? getTypedAccessToken() {
    return _sessionStorage.getSession()?.typedAccessToken;
  }

  String? getAccessToken() {
    return _sessionStorage.getSession()?.accessToken;
  }

  bool get isDemoMode => _sessionStorage.getSession()?.isDemoMode ?? false;

  JwtUserData? getJwtUserData() {
    final jwt = getAccessToken();
    return jwt != null ? JwtUserData.fromJwtJson(JwtDecoder.decode(jwt)) : null;
  }

  bool get _isLoggedInWithKeycloak => _keycloakWrapper.accessToken != null;

  Future<bool> _refreshDemoSession() async {
    final response = await _mobileService.createDemoSession();
    if (!response.isSuccessful || response.body == null) {
      await _clearTelemetryIdentity();
      _emitAuthInitial();
      AppLog.warn(
          'Demo session refresh failed: ${_extractResponseMessage(response)}');
      return false;
    }

    await _applySession(
      Session.fromJson(response.body).copyWith(authProvider: 'demo'),
    );
    return true;
  }

  Future<void> _applySession(Session session) async {
    await _sessionStorage.setSession(session);
    await _syncTelemetryIdentity();
    _emitAuthenticated();
  }

  Future<void> _ensureStoredSession() async {
    final session = _sessionStorage.getSession();
    if (session == null || session.isDemoMode) {
      return;
    }

    try {
      final response = await _mobileService.ensureMySession();
      if (response.isSuccessful) {
        return;
      }

      throw SessionProvisioningException(
        kind: _provisioningFailureKind(response.statusCode),
        message: _extractResponseMessage(response),
      );
    } on SessionProvisioningException {
      rethrow;
    } catch (error) {
      throw SessionProvisioningException(
        kind: SessionProvisioningFailureKind.transient,
        message: error.toString(),
      );
    }
  }

  SessionProvisioningFailureKind _provisioningFailureKind(int statusCode) {
    return switch (statusCode) {
      401 || 403 || 404 => SessionProvisioningFailureKind.authRejected,
      _ => SessionProvisioningFailureKind.transient,
    };
  }

  Future<void> _rejectStoredSession() async {
    await _sessionStorage.clearSession();
    await _clearTelemetryIdentity();
    _emitAuthInitial();
  }

  Future<void> _syncTelemetryIdentity() async {
    final userData = getJwtUserData();
    final userId = userData?.uuid ?? (isDemoMode ? 'demo' : null);
    if (userId != null && userId.isNotEmpty) {
      await OshCrashReporter.setUserId(userId);
    } else {
      await OshCrashReporter.clearUserId();
    }

    final analyticsUserId = userData?.uuid;
    await OshAnalytics.setUserId(analyticsUserId);

    final authProvider = _sessionStorage.getSession()?.authProvider ??
        (isDemoMode ? 'demo' : null);
    await CrashlyticsContextSync.syncSessionAuthContext(
      isDemoMode: isDemoMode,
      authProvider: authProvider,
    );

    await OshAnalytics.setUserProperty(
      name: OshAnalyticsUserProperties.sessionMode,
      value: isDemoMode ? 'demo' : 'real',
    );
    await OshAnalytics.setUserProperty(
      name: OshAnalyticsUserProperties.authProvider,
      value: authProvider,
    );
  }

  Future<void> _clearTelemetryIdentity() async {
    await OshAnalytics.resetSessionContext();
    await OshCrashReporter.clearUserId();
    await OshCrashReporter.clearContext(CrashlyticsContextKeys.logoutResetKeys);
  }

  String _extractResponseMessage(dynamic response) {
    return RestResponseErrorMapper.messageFromResponse(response);
  }
}
