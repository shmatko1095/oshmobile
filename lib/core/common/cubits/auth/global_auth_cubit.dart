import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:keycloak_wrapper/keycloak_wrapper.dart';
import 'package:oshmobile/core/common/entities/jwt_user_data.dart';
import 'package:oshmobile/core/common/entities/session.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';
import 'package:oshmobile/core/network/chopper_client/auth/auth_service.dart';
import 'package:oshmobile/core/network/chopper_client/core/session_storage.dart';

part 'global_auth_state.dart';

class GlobalAuthCubit extends Cubit<GlobalAuthState> {
  final AuthService _authService;
  final SessionStorage _sessionStorage;
  final KeycloakWrapper _keycloakWrapper;

  GlobalAuthCubit({
    required AuthService authService,
    required SessionStorage sessionStorage,
    required KeycloakWrapper keycloakWrapper,
  })  : _authService = authService,
        _sessionStorage = sessionStorage,
        _keycloakWrapper = keycloakWrapper,
        super(const AuthInitial(revision: 0));

  int _revision = 0;
  void _emitAuthenticated() => emit(AuthAuthenticated(revision: ++_revision));
  void _emitInitial() => emit(AuthInitial(revision: ++_revision));

  Future<void> checkAuthStatus() async {
    await refreshToken();
  }

  Future<void> signedIn(Session session) async {
    await _sessionStorage.setSession(session);
    OshCrashReporter.setUserId(getJwtUserData()?.email ?? getJwtUserData()!.uuid);
    _emitAuthenticated();
  }

  Future<void> signedOut() async {
    if (_isLoggedInWithKeycloak) {
      try {
        await _keycloakWrapper.logout();
      } catch (e) {
        debugPrint('Keycloak logout failed: $e');
      }
    }

    await _sessionStorage.clearSession();
    _emitInitial();
  }

  Future<bool> refreshToken() async {
    try {
      final currentSession = _sessionStorage.getSession();
      if (currentSession == null) {
        _emitInitial();
        return false;
      }

      final response = await _authService.refreshToken(
        refreshToken: currentSession.refreshToken,
      );
      if (response.isSuccessful) {
        final newSession = currentSession.copyWith(accessToken: response.body!.accessToken);
        await _sessionStorage.setSession(newSession);
        OshCrashReporter.setUserId(getJwtUserData()?.email ?? getJwtUserData()!.uuid);
        _emitAuthenticated();
        return true;
      } else {
        _emitInitial();
        log(response.bodyString);
        return false;
      }
    } catch (error) {
      _emitInitial();
      return false;
    }
  }

  String? getTypedAccessToken() {
    return _sessionStorage.getSession()?.typedAccessToken;
  }

  String? getAccessToken() {
    return _sessionStorage.getSession()?.accessToken;
  }

  JwtUserData? getJwtUserData() {
    final jwt = getAccessToken();
    return jwt != null ? JwtUserData.fromJwtJson(JwtDecoder.decode(jwt)) : null;
  }

  bool get _isLoggedInWithKeycloak => _keycloakWrapper.accessToken != null;
}
