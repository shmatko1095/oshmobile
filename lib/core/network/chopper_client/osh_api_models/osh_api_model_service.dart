import 'package:chopper/chopper.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api_models/requests/create_model_request.dart';
import 'package:oshmobile/core/secrets/app_secrets.dart';

part 'osh_api_model_service.chopper.dart';

@ChopperApi(baseUrl: "${AppSecrets.oshApiEndpoint}/models")
abstract class ApiModelService extends ChopperService {
  static ApiModelService create([ChopperClient? client]) => _$ApiModelService(client);

  void updateClient(ChopperClient client) {
    this.client = client;
  }

  @POST()
  Future<Response> createModel({
    @Body() required CreateModelRequest request,
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
}
