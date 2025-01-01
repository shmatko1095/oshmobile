import 'dart:async';

import 'package:chopper/chopper.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api_device/requests/assign_device_request.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api_device/requests/unassign_device_request.dart';
import 'package:oshmobile/core/secrets/app_secrets.dart';

part 'osh_api_user_device_service.chopper.dart';

@ChopperApi(baseUrl: AppSecrets.oshApiUserDeviceEndpoint)
abstract class OshApiUserDeviceService extends ChopperService {
  static OshApiUserDeviceService create([ChopperClient? client]) =>
      _$OshApiUserDeviceService(client);

  void updateClient(ChopperClient client) {
    this.client = client;
  }

  @Put()
  Future<Response> assignDevice({
    @Path('uuid') required String uuid,
    @Body() required AssignDeviceRequest request,
  });

  @Delete()
  Future<Response> unassignDevice({
    @Path('uuid') required String uuid,
    @Body() required UnassignDeviceRequest request,
  });

  @Get()
  Future<Response> getDeviceList({
    @Path('uuid') required String uuid,
  });
}
