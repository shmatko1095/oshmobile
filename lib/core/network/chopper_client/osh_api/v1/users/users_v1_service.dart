import 'dart:async';
import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/users/requests/register_user_request.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/users/requests/send_reset_password_email_request.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/users/requests/send_verification_email_request.dart';
import 'package:oshmobile/core/secrets/app_secrets.dart';

part 'users_v1_service.chopper.dart';

@ChopperApi(baseUrl: "${AppSecrets.oshApiBaseUrl}/v1/users")
abstract class UsersV1Service extends ChopperService {
  static UsersV1Service create([ChopperClient? client]) =>
      _$UsersV1Service(client);

  void updateClient(ChopperClient client) {
    this.client = client;
  }

  @POST()
  Future<Response> registerUser({
    @Header(HttpHeaders.authorizationHeader) required String accessToken,
    @Body() required RegisterUserRequest request,
  });

  @POST(path: "/verify-email")
  Future<Response> sendVerificationEmail({
    @Header(HttpHeaders.authorizationHeader) required String accessToken,
    @Body() required SendVerificationEmailRequest request,
  });

  @POST(path: "/reset-password")
  Future<Response> sendResetPasswordEmail({
    @Header(HttpHeaders.authorizationHeader) required String accessToken,
    @Body() required SendResetPasswordEmailRequest request,
  });
}
