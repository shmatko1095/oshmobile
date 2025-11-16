import 'dart:async';
import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:oshmobile/core/common/cubits/auth/global_auth_cubit.dart';

class ApiAuthenticator extends Authenticator {
  Completer<bool>? _refreshCompleter;

  final GlobalAuthCubit _globalAuthCubit;

  ApiAuthenticator({
    required GlobalAuthCubit globalAuthCubit,
  }) : _globalAuthCubit = globalAuthCubit;

  @override
  FutureOr<Request?> authenticate(
    Request request,
    Response response, [
    Request? originalRequest,
  ]) async {
    Request? result;

    if (response.statusCode == HttpStatus.unauthorized) {
      if (_refreshCompleter != null) {
        final success = await _refreshCompleter!.future;
        if (success) {
          result = _buildAuthenticatedRequest(request);
        }
      } else {
        _refreshCompleter = Completer<bool>();

        try {
          final success = await _globalAuthCubit.refreshToken();
          _refreshCompleter?.complete(success);

          if (success) {
            result = _buildAuthenticatedRequest(request);
          }
        } catch (_) {
          _refreshCompleter?.complete(false);
        } finally {
          _refreshCompleter = null;
        }
      }
    }

    return result;
  }

  Request? _buildAuthenticatedRequest(Request request) {
    final typedToken = _globalAuthCubit.getTypedAccessToken();
    return typedToken == null
        ? null
        : applyHeader(
            request,
            HttpHeaders.authorizationHeader,
            typedToken,
          );
  }
}
