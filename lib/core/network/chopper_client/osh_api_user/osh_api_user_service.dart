import 'dart:async';
import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api_user/requests/assign_device_request.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api_user/requests/register_user_request.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api_user/requests/send_reset_password_email_request.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api_user/requests/send_verification_email_request.dart';
import 'package:oshmobile/core/secrets/app_secrets.dart';

part 'osh_api_user_service.chopper.dart';

@ChopperApi(baseUrl: "${AppSecrets.oshApiEndpoint}/users")
abstract class ApiUserService extends ChopperService {
  static ApiUserService create([ChopperClient? client]) =>
      _$ApiUserService(client);

  void updateClient(ChopperClient client) {
    this.client = client;
  }

  @GET(path: '/{id}')
  Future<Response> get({
    @Path('id') required String userId,
  });

  @GET(path: '/{id}/devices')
  Future<Response> getDevices({
    @Path('id') required String userId,
  });

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

  @DELETE(path: '/{id}')
  Future<Response> delete({
    @Path('id') required String userId,
  });

  @PUT(path: '/{id}/device/{sn}')
  Future<Response> assignDevice({
    @Path('id') required String userId,
    @Path('sn') required String deviceSn,
    @Body() required AssignDeviceRequest request,
  });

  @DELETE(path: '/{id}/device/{deviceId}')
  Future<Response> unassignDevice({
    @Path('id') required String userId,
    @Path('deviceId') required String deviceId,
  });
}
