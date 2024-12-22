import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/entities/session.dart';
import 'package:oshmobile/core/network/chopper_client/auth/auth_service.dart';
import 'package:oshmobile/core/network/chopper_client/core/session_storage.dart';

part 'global_auth_state.dart';

class GlobalAuthCubit extends Cubit<GlobalAuthState> {
  final AuthService _authService;
  final SessionStorage _sessionStorage;

  GlobalAuthCubit({
    required AuthService authService,
    required SessionStorage sessionStorage,
  })  : _authService = authService,
        _sessionStorage = sessionStorage,
        super(AuthInitial());

  void checkAuthStatus() {
    final session = _sessionStorage.getSession();
    if (session != null && session.isRefreshTokenValid) {
      emit(const AuthAuthenticated());
    } else {
      emit(const AuthInitial());
    }
  }

  Future<void> signedIn(Session session) async {
    await _sessionStorage.setSession(session);
    emit(const AuthAuthenticated());
  }

  Future<void> signedOut() async {
    await _sessionStorage.clearSession();
    emit(const AuthInitial());
  }

  Future<bool> refreshToken() async {
    try {
      final currentSession = _sessionStorage.getSession();
      if (currentSession == null) {
        emit(const AuthInitial());
        return false;
      }

      final response = await _authService.refreshToken(
        refreshToken: currentSession.refreshToken,
      );

      if (response.isSuccessful && response.body != null) {
        final newSession = Session.fromJson(response.body);
        await _sessionStorage.setSession(newSession);
        emit(const AuthAuthenticated());
        return true;
      } else {
        emit(const AuthInitial());
        log(response.bodyString);
        return false;
      }
    } catch (error) {
      emit(const AuthInitial());
      return false;
    }
  }

  String? getAccessToken() {
    return _sessionStorage.getSession()?.accessToken;
  }
}
