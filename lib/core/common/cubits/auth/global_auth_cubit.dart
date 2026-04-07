import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:keycloak_wrapper/keycloak_wrapper.dart';
import 'package:oshmobile/core/common/entities/jwt_user_data.dart';
import 'package:oshmobile/core/common/entities/session.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';
import 'package:oshmobile/core/network/chopper_client/auth/auth_service.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_service.dart';
import 'package:oshmobile/core/network/chopper_client/core/session_storage.dart';

part 'global_auth_state.dart';

class GlobalAuthCubit extends Cubit<GlobalAuthState> {
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

  void _emitAuthInitial() {
    _revision++;
    emit(AuthInitial(_revision));
  }

  void _emitAuthenticated() {
    _revision++;
    emit(AuthAuthenticated(_revision));
  }

  Future<void> checkAuthStatus() async {
    await refreshToken();
  }

  Future<void> signedIn(Session session) async {
    await _sessionStorage.setSession(session);
    _syncCrashReporterUser();
    _emitAuthenticated();
  }

  Future<void> signedOut() async {
    final shouldLogoutKeycloak = !isDemoMode && _isLoggedInWithKeycloak;
    if (shouldLogoutKeycloak) {
      try {
        await _keycloakWrapper.logout();
      } catch (e) {
        debugPrint('Keycloak logout failed: $e');
      }
    }

    await _sessionStorage.clearSession();
    _emitAuthInitial();
  }

  Future<bool> refreshToken() async {
    try {
      final currentSession = _sessionStorage.getSession();
      if (currentSession == null) {
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
        _emitAuthInitial();
        log(response.bodyString);
        return false;
      }

      await _applySession(Session.fromJson(response.body));
      return true;
    } catch (error, st) {
      OshCrashReporter.logNonFatal(error, st, reason: 'Token refresh failed');
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
      _emitAuthInitial();
      log(_extractResponseMessage(response));
      return false;
    }

    await _applySession(Session.fromJson(response.body));
    return true;
  }

  Future<void> _applySession(Session session) async {
    await _sessionStorage.setSession(session);
    _syncCrashReporterUser();
    _emitAuthenticated();
  }

  void _syncCrashReporterUser() {
    final userData = getJwtUserData();
    final userId =
        userData?.email ?? userData?.uuid ?? (isDemoMode ? 'demo' : null);
    if (userId != null && userId.isNotEmpty) {
      OshCrashReporter.setUserId(userId);
    }
  }

  String _extractResponseMessage(dynamic response) {
    try {
      final body = response.body;
      if (body is Map) {
        final message = body['message']?.toString();
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }

      final error = response.error;
      if (error is Map) {
        final message = error['message']?.toString();
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
      if (error is String && error.isNotEmpty) {
        final decoded = jsonDecode(error);
        if (decoded is Map) {
          final message = decoded['message']?.toString();
          if (message != null && message.isNotEmpty) {
            return message;
          }
        }
      }
    } catch (_) {
      // Fall through to the generic status-based message.
    }

    return 'HTTP ${response.statusCode}';
  }
}
