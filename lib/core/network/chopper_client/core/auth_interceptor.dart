import 'dart:async';
import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:oshmobile/core/common/cubits/auth/global_auth_cubit.dart';
import 'package:oshmobile/core/network/network_utils/extensions.dart';

class AuthInterceptor implements Interceptor {
  final GlobalAuthCubit _authCubit;

  AuthInterceptor({required GlobalAuthCubit globalAuthCubit}) : _authCubit = globalAuthCubit;

  @override
  FutureOr<Response<BodyType>> intercept<BodyType>(
    Chain<BodyType> chain,
  ) async {
    final request = chain.request;

    final processedRequest = request.isAuthRequest
        ? request
        : _authCubit.getTypedAccessToken() != null
            ? applyHeader(
                request,
                HttpHeaders.authorizationHeader,
                _authCubit.getTypedAccessToken()!,
                override: false,
              )
            : request;

    return chain.proceed(processedRequest);
  }
}
