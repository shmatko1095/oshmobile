import 'dart:async';

import 'package:chopper/chopper.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api_device/requests/assign_device_request.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api_device/requests/unassign_device_request.dart';
import 'package:oshmobile/core/secrets/app_secrets.dart';

part 'osh_api_user_device_service.chopper.dart';

@ChopperApi(baseUrl: AppSecrets.oshApiEndpoint)
abstract class OshApiUserDeviceService extends ChopperService {
  static OshApiUserDeviceService create([ChopperClient? client]) =>
      _$OshApiUserDeviceService(client);

  void updateClient(ChopperClient client) {
    this.client = client;
  }

  @Put(path: "{uuid}/device")
  Future<Response> assignDevice({
    @Path('uuid') required String uuid,
    @Body() required AssignDeviceRequest request,
  });

  @Delete(path: "{uuid}/device")
  Future<Response> unassignDevice({
    @Path('uuid') required String uuid,
    @Body() required UnassignDeviceRequest request,
  });

  @Get(path: "{uuid}/device")
  Future<Response> getDeviceList({
    @Path('uuid') required String uuid,
  });
}
