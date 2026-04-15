import 'package:oshmobile/core/error/exceptions.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_response_mapper.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_service.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/requests/update_my_device_user_data_request.dart';
import 'package:oshmobile/features/device_management/data/datasources/device_management_remote_data_source.dart';

class DeviceManagementRemoteDataSourceImpl
    implements DeviceManagementRemoteDataSource {
  final MobileV1Service _mobileService;

  const DeviceManagementRemoteDataSourceImpl({
    required MobileV1Service mobileService,
  }) : _mobileService = mobileService;

  @override
  Future<void> renameDevice({
    required String serial,
    required String alias,
    required String description,
  }) async {
    try {
      final response = await _mobileService.updateMyDeviceUserData(
        serial: serial,
        request: UpdateMyDeviceUserDataRequest(
          alias: alias,
          description: description,
        ),
      );
      MobileV1ResponseMapper.ensureSuccess(response);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> removeDevice({
    required String serial,
  }) async {
    try {
      final response = await _mobileService.unassignMyDevice(serial: serial);
      MobileV1ResponseMapper.ensureSuccess(response);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
