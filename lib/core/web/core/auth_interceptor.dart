import 'dart:async';
import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:oshmobile/core/web/chopper_example/core/extensions.dart';
import 'package:oshmobile/core/web/chopper_example/core/session_storage.dart';

class AuthInterceptor implements Interceptor {
  final SessionStorage _sessionRepository;

  AuthInterceptor({required SessionStorage sessionRepository})
      : _sessionRepository = sessionRepository;

  @override
  FutureOr<Response<BodyType>> intercept<BodyType>(
    Chain<BodyType> chain,
  ) async {
    if (chain.request.isAuthRequest) {
      return chain.proceed(chain.request);
    }

    final session = _sessionRepository.session;
    if (session != null) {
      final response = await chain.proceed(
        applyHeader(
          chain.request,
          HttpHeaders.authorizationHeader,
          session.accessToken,
          override: false,
        ),
      );
      return response;
    }

    return chain.proceed(chain.request);
  }
}
