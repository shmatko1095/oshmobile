import 'dart:async';

import 'package:chopper/chopper.dart';
import 'package:oshmobile/core/secrets/app_secrets.dart';

part 'auth_service.chopper.dart';

@ChopperApi(baseUrl: AppSecrets.oshAccessTokenUrl)
abstract class AuthService extends ChopperService {
  static AuthService create([ChopperClient? client]) => _$AuthService(client);

  void updateClient(ChopperClient client) {
    this.client = client;
  }

  @POST()
  @formUrlEncoded
  Future<Response> signInWithUserCred({
    @Field() required String username,
    @Field() required String password,
    @Field("grant_type") String grantType = "password",
    @Field("client_id") String clientId = AppSecrets.oshClientId,
    @Field("client_secret") String clientSecret = AppSecrets.oshClientSecret,
  });

  @POST()
  @formUrlEncoded
  Future<Response> signInWithClientCred({
    @Field("grant_type") String grantType = "client_credentials",
    @Field("client_id") String clientId = AppSecrets.oshClientId,
    @Field("client_secret") String clientSecret = AppSecrets.oshClientSecret,
  });

  @POST()
  @formUrlEncoded
  Future<Response> refreshToken({
    @Field("refresh_token") required String refreshToken,
    @Field("grant_type") String grantType = "refresh_token",
    @Field("client_id") String clientId = AppSecrets.oshClientId,
    @Field("client_secret") String clientSecret = AppSecrets.oshClientSecret,
  });
}
