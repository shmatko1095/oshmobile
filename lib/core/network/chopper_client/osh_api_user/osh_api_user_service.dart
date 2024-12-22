import 'dart:async';
import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api_user/requests/register_user_request.dart';
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
}
