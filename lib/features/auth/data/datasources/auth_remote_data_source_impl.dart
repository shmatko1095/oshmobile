import 'dart:convert';

import 'package:oshmobile/core/common/entities/session.dart';
import 'package:oshmobile/core/error/exceptions.dart';
import 'package:oshmobile/core/network/chopper_client/auth/auth_service.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api_user/osh_api_user_service.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api_user/requests/register_user_request.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api_user/requests/send_reset_password_email_request.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api_user/requests/send_verification_email_request.dart';
import 'package:oshmobile/core/secrets/app_secrets.dart';
import 'package:oshmobile/features/auth/data/datasources/auth_remote_data_source.dart';

class OshAuthRemoteDataSourceImpl implements IAuthRemoteDataSource {
  final AuthService _authClient;
  final ApiUserService _oshApiUserService;

  OshAuthRemoteDataSourceImpl({
    required AuthService authClient,
    required ApiUserService oshApiUserService,
  })  : _authClient = authClient,
        _oshApiUserService = oshApiUserService;

  @override
  Future<Session> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _authClient.signInWithUserCred(
      username: email,
      password: password,
      clientId: AppSecrets.clientId,
      clientSecret: AppSecrets.clientSecret,
    );

    if (response.isSuccessful && response.body != null) {
      return Session.fromJson(response.body);
    } else {
      final error = jsonDecode(response.error as String);
      final errorDescription = error["error_description"] as String;
      if (errorDescription.endsWith("Account is not fully set up")) {
        throw const EmailNotVerifiedException();
      } else if (errorDescription.endsWith("Invalid user credentials")) {
        throw const InvalidUserCredentialsException();
      } else {
        throw ServerException(errorDescription);
      }
    }
  }

  @override
  Future<Session> signInWithRefreshToken({
    required String refreshToken,
  }) async {
    // Uses Keycloak /token endpoint with grant_type=refresh_token.
    final response = await _authClient.refreshToken(
      refreshToken: refreshToken,
      clientId: AppSecrets.clientId,
      clientSecret: AppSecrets.clientSecret,
    );

    if (response.isSuccessful && response.body != null) {
      return Session.fromJson(response.body);
    } else {
      throw ServerException(response.error as String);
    }
  }

  @override
  Future<void> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    String clientToken = await _getClientToken();
    final response = await _oshApiUserService.registerUser(
        accessToken: clientToken,
        request: RegisterUserRequest(firstName: firstName, lastName: lastName, email: email, password: password));

    if (!response.isSuccessful) {
      String error = response.error as String;
      if (error.endsWith("Conflict")) {
        throw const ConflictException();
      } else {
        throw ServerException(response.error as String);
      }
    }
  }

  @override
  Future<void> resetPassword({
    required String email,
  }) async {
    String clientToken = await _getClientToken();
    final response = await _oshApiUserService.sendResetPasswordEmail(
        accessToken: clientToken, request: SendResetPasswordEmailRequest(email: email));

    if (!response.isSuccessful) {
      throw ServerException(response.error as String);
    }
  }

  @override
  Future<void> verifyEmail({
    required String email,
  }) async {
    String clientToken = await _getClientToken();
    final response = await _oshApiUserService.sendVerificationEmail(
        accessToken: clientToken, request: SendVerificationEmailRequest(email: email));

    if (!response.isSuccessful) {
      throw ServerException(response.error as String);
    }
  }

  Future<String> _getClientToken() async {
    final response = await _authClient.signInWithClientCred(
      clientId: AppSecrets.clientId,
      clientSecret: AppSecrets.clientSecret,
    );

    if (response.isSuccessful && response.body != null) {
      String accessToken = Session.fromJson(response.body).typedAccessToken;
      return accessToken;
    } else {
      throw ServerException(response.error as String);
    }
  }
}
