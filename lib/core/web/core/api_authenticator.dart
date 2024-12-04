import 'dart:async';
import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:oshmobile/core/common/cubits/app_user/app_user_cubit.dart';
import 'package:oshmobile/core/web/auth/auth_service.dart';
import 'package:oshmobile/core/web/chopper_example/core/extensions.dart';
import 'package:oshmobile/core/web/chopper_example/core/session_storage.dart';
import 'package:oshmobile/core/web/chopper_example/models/session.dart';

/// Provides authenticator for every APIs and handles refreshing
/// access token for unauthorized APIs.
class ApiAuthenticator extends Authenticator {
  /// Completer to prevent multiple token refreshes at the same time.
  Completer<bool>? _completer;

  final SessionStorage _sessionRepository;
  final AppUserCubit _appUserCubit;
  final AuthService _authService;

  ApiAuthenticator({
    required SessionStorage sessionRepository,
    required AppUserCubit appUserCubit,
    required AuthService authService,
  })  : _sessionRepository = sessionRepository,
        _appUserCubit = appUserCubit,
        _authService = authService;

  @override
  FutureOr<Request?> authenticate(
    Request request,
    Response response, [
    Request? originalRequest,
  ]) async {
    if (request.isAuthRequest && response.isSuccessful) {
      final session = Session.fromJson(response.body);
      _sessionRepository.setSession(session);
    }

    if (response.statusCode == HttpStatus.unauthorized) {
      if (request.isAuthRequest) {
        _finishCompleter(complete: false);
        _sessionRepository.setSession(null);
        _appUserCubit.updateUser(null);
        return null;
      }

      // If completer is running, hold the request until it completes.
      if (_completer != null && !_completer!.isCompleted) {
        final complete = await _completer?.future;
        if (complete ?? false) return _applyAuthHeader(request);
        return null;
      }

      final session = _sessionRepository.session;
      if (session == null) return null;

      if (JwtDecoder.isExpired(session.accessToken)) {
        final result = await _authService.refreshToken(
          refreshToken: session.refreshToken,
        );

        if (result.isSuccessful && result.body != null) {
          final session = Session.fromJson(result.body);
          _sessionRepository.setSession(session);
        }
      }

      _completer ??= Completer<bool>();

      // Complete the completer on successfully refreshing the token.
      if (_completer != null && !_completer!.isCompleted) {
        _finishCompleter();
      }

      return _applyAuthHeader(request);
    }
    return null;
  }

  void _finishCompleter({bool complete = true}) {
    _completer?.complete(complete);
    _completer = null;
  }

  Request _applyAuthHeader(Request request) {
    return applyHeader(
      request,
      HttpHeaders.authorizationHeader,
      '${_sessionRepository.session?.accessToken}',
    );
  }
}
