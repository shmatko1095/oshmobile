import 'dart:convert';

import 'package:oshmobile/core/common/entities/session.dart';
import 'package:oshmobile/core/error/exceptions.dart';
import 'package:oshmobile/core/network/chopper_client/auth/auth_service.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api_user/osh_api_user_service.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api_user/requests/register_user_request.dart';
import 'package:oshmobile/core/secrets/app_secrets.dart';
import 'package:oshmobile/features/auth/data/datasources/auth_remote_data_source.dart';

class OshRemoteDataSourceImpl implements IAuthRemoteDataSource {
  final AuthService _authClient;
  final OshApiUserService _oshApiUserService;

  OshRemoteDataSourceImpl({
    required AuthService authClient,
    required OshApiUserService oshApiUserService,
  })  : _authClient = authClient,
        _oshApiUserService = oshApiUserService;

  @override
  Future<Session> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _authClient.signInWithUserCred(
        username: email,
        password: password,
        clientId: AppSecrets.oshClientId,
        clientSecret: AppSecrets.oshClientSecret,
      );

      if (response.isSuccessful && response.body != null) {
        return Session.fromJson(response.body);
      } else {
        final error = jsonDecode(response.error as String);
        throw ServerException(error["error_description"] as String);
      }
    } on ServerException catch (_) {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _authClient.signInWithClientCred(
        clientId: AppSecrets.oshClientId,
        clientSecret: AppSecrets.oshClientSecret,
      );

      if (response.isSuccessful && response.body != null) {
        String accessToken = Session.fromJson(response.body).typedAccessToken;

        final registeredResponse = await _oshApiUserService.registerUser(
            accessToken: accessToken,
            request: RegisterUserRequest(
                firstName: firstName,
                lastName: lastName,
                email: email,
                password: password));

        if (!(registeredResponse.isSuccessful &&
            registeredResponse.body != null)) {
          throw ServerException(registeredResponse.error as String);
        }
      } else {
        throw ServerException(response.error as String);
      }
    } on ServerException catch (_) {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
