import 'package:oshmobile/core/error/exceptions.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/requests/claim_my_device_request.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_response_mapper.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_service.dart';
import 'package:oshmobile/features/home/data/datasources/user_remote_data_source.dart';

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final MobileV1Service _mobileService;

  const UserRemoteDataSourceImpl({
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
  Future<void> unassignDevice({
    required String serial,
  }) async {
    final response = await _mobileService.unassignMyDevice(serial: serial);
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
