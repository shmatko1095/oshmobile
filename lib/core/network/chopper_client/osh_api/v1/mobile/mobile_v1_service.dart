import 'dart:async';

import 'package:chopper/chopper.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/requests/claim_my_device_request.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/requests/update_my_device_user_data_request.dart';
import 'package:oshmobile/core/secrets/app_secrets.dart';

part 'mobile_v1_service.chopper.dart';

@ChopperApi(baseUrl: "${AppSecrets.oshApiBaseUrl}/v1/mobile")
abstract class MobileV1Service extends ChopperService {
  static MobileV1Service create([ChopperClient? client]) =>
      _$MobileV1Service(client);

  void updateClient(ChopperClient client) {
    this.client = client;
  }

  @GET(path: '/me/devices')
  Future<Response> listMyDevices();

  @POST(path: '/demo/session')
  Future<Response> createDemoSession();

  @GET(path: '/devices/{serial}')
  Future<Response> getMyDevice({
    @Path('serial') required String serial,
  });

  @GET(path: '/devices/{serial}/users')
  Future<Response> getMyDeviceUsers({
    @Path('serial') required String serial,
  });

  @POST(path: '/devices/{serial}/claim')
  Future<Response> claimMyDevice({
    @Path('serial') required String serial,
    @Body() required ClaimMyDeviceRequest request,
  });

  @DELETE(path: '/devices/{serial}')
  Future<Response> unassignMyDevice({
    @Path('serial') required String serial,
  });

  @PUT(path: '/devices/{serial}/userdata')
  Future<Response> updateMyDeviceUserData({
    @Path('serial') required String serial,
    @Body() required UpdateMyDeviceUserDataRequest request,
  });

  @POST(path: '/me/account-deletion')
  Future<Response> requestMyAccountDeletion();

  @GET(path: '/devices/{serial}/telemetry/history')
  Future<Response> getMyDeviceTelemetryHistory({
    @Path('serial') required String serial,
    @Query('series_keys') required String seriesKeys,
    @Query('from') required String from,
    @Query('to') required String to,
    @Query('resolution') String resolution = 'auto',
  });

  @GET(path: '/client-policy')
  Future<Response> getClientPolicy({
    @Query('platform') required String platform,
    @Query('app_version') required String appVersion,
    @Query('build') int? build,
  });
}
