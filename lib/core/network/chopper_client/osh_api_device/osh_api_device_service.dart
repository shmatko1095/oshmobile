import 'package:chopper/chopper.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api_device/requests/create_device_request.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api_device/requests/update_device_user_data.dart';
import 'package:oshmobile/core/secrets/app_secrets.dart';

part 'osh_api_device_service.chopper.dart';

@ChopperApi(baseUrl: "${AppSecrets.oshApiEndpoint}/devices")
abstract class ApiDeviceService extends ChopperService {
  static ApiDeviceService create([ChopperClient? client]) =>
      _$ApiDeviceService(client);

  void updateClient(ChopperClient client) {
    this.client = client;
  }

  @POST()
  Future<Response> createDevice({
    @Body() required CreateDeviceRequest request,
  });

  @GET()
  Future<Response> getAll();

  @GET(path: "/{id}")
  Future<Response> get({
    @Path('id') required String id,
  });

  @DELETE(path: "/{id}")
  Future<Response> delete({
    @Path('id') required String id,
  });

  @PUT(path: "/{id}/userdata")
  Future<Response> updateDeviceUserData({
    @Path('id') required String id,
    @Body() required UpdateDeviceUserData request,
  });
}
