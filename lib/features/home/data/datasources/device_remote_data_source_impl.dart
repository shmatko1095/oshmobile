import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/error/exceptions.dart';
import 'package:oshmobile/core/network/mobile/mobile_api_client.dart';
import 'package:oshmobile/features/home/data/datasources/device_remote_data_source.dart';

class DeviceRemoteDataSourceImpl implements DeviceRemoteDataSource {
  final MobileApiClient mobileApiClient;

  const DeviceRemoteDataSourceImpl({required this.mobileApiClient});

  @override
  Future<Device> get({
    required String serial,
  }) async {
    try {
      return await mobileApiClient.getMyDevice(serial: serial);
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
    await mobileApiClient.updateMyDeviceUserData(
      serial: serial,
      alias: alias,
      description: description,
    );
  }
}
