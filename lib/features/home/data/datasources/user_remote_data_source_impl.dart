import 'package:oshmobile/core/error/exceptions.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/network/mobile/mobile_api_client.dart';
import 'package:oshmobile/features/home/data/datasources/user_remote_data_source.dart';

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final MobileApiClient mobileApiClient;

  const UserRemoteDataSourceImpl({required this.mobileApiClient});

  @override
  Future<void> assignDevice({
    required String deviceSn,
    required String deviceSc,
  }) async {
    await mobileApiClient.claimMyDevice(
      serial: deviceSn,
      secureCode: deviceSc,
    );
  }

  @override
  Future<void> unassignDevice({
    required String serial,
  }) async {
    await mobileApiClient.unassignMyDevice(serial: serial);
  }

  @override
  Future<List<Device>> getDevices() async {
    try {
      return await mobileApiClient.listMyDevices();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
