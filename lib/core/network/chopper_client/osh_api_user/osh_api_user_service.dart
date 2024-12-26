import 'dart:async';
import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api_user/requests/register_user_request.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api_user/requests/send_reset_password_email_request.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api_user/requests/send_verification_email_request.dart';
import 'package:oshmobile/core/secrets/app_secrets.dart';

part 'osh_api_user_service.chopper.dart';

@ChopperApi(baseUrl: AppSecrets.oshApiUserEndpoint)
abstract class OshApiUserService extends ChopperService {
  static OshApiUserService create([ChopperClient? client]) =>
      _$OshApiUserService(client);

  void updateClient(ChopperClient client) {
    this.client = client;
  }

  @Post()
  Future<Response> registerUser({
    @Header(HttpHeaders.authorizationHeader) required String accessToken,
    @Body() required RegisterUserRequest request,
  });

  @Post(path: "/verify-email")
  Future<Response> sendVerificationEmail({
    @Header(HttpHeaders.authorizationHeader) required String accessToken,
    @Body() required SendVerificationEmailRequest request,
  });

  @Post(path: "/reset-password")
  Future<Response> sendResetPasswordEmail({
    @Header(HttpHeaders.authorizationHeader) required String accessToken,
    @Body() required SendResetPasswordEmailRequest request,
  });
}
