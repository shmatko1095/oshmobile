import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/error/exceptions.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/requests/update_my_device_user_data_request.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_response_mapper.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_service.dart';
import 'package:oshmobile/features/home/data/datasources/device_remote_data_source.dart';

class DeviceRemoteDataSourceImpl implements DeviceRemoteDataSource {
  final MobileV1Service _mobileService;

  const DeviceRemoteDataSourceImpl({
    required MobileV1Service mobileService,
  }) : _mobileService = mobileService;

  @override
  Future<Device> get({
    required String serial,
  }) async {
    try {
      final response = await _mobileService.getMyDevice(serial: serial);
      return MobileV1ResponseMapper.requireDevice(response);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateDeviceUserData({
    required String serial,
    required String alias,
    required String description,
  }) async {
    final response = await _mobileService.updateMyDeviceUserData(
      serial: serial,
      request: UpdateMyDeviceUserDataRequest(
        alias: alias,
        description: description,
      ),
    );
    MobileV1ResponseMapper.ensureSuccess(response);
  }
}
