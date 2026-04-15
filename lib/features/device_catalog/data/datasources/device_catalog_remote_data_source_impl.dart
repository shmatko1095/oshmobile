import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/error/exceptions.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_response_mapper.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_service.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/requests/claim_my_device_request.dart';
import 'package:oshmobile/features/device_catalog/data/datasources/device_catalog_remote_data_source.dart';

class DeviceCatalogRemoteDataSourceImpl
    implements DeviceCatalogRemoteDataSource {
  final MobileV1Service _mobileService;

  const DeviceCatalogRemoteDataSourceImpl({
    required MobileV1Service mobileService,
  }) : _mobileService = mobileService;

  @override
  Future<void> assignDevice({
    required String deviceSn,
    required String deviceSc,
  }) async {
    final response = await _mobileService.claimMyDevice(
      serial: deviceSn,
      request: ClaimMyDeviceRequest(secureCode: deviceSc),
    );
    MobileV1ResponseMapper.ensureSuccess(response);
  }

  @override
  Future<List<Device>> getDevices() async {
    try {
      final response = await _mobileService.listMyDevices();
      return MobileV1ResponseMapper.requireDeviceList(response);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
