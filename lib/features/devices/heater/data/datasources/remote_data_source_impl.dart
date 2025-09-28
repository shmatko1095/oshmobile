import 'dart:convert';

import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/error/exceptions.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api_device/osh_api_user_device_service.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api_device/requests/assign_device_request.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api_device/requests/unassign_device_request.dart';
import 'package:oshmobile/features/home/data/datasources/remote_data_source.dart';
import 'package:oshmobile/features/home/data/models/device_list_response.dart';

class OshDeviceRemoteDataSourceImpl implements OshRemoteDataSource {
  final OshApiUserDeviceService oshApiUserDeviceService;

  const OshDeviceRemoteDataSourceImpl({required this.oshApiUserDeviceService});

  @override
  Future<List<Device>> assignDevice({
    required String uuid,
    required String sn,
    required String sc,
  }) async {
    final response = await oshApiUserDeviceService.assignDevice(
      uuid: uuid,
      request: AssignDeviceRequest(sn: sn, sc: sc),
    );
    if (response.isSuccessful && response.body != null) {
      return DeviceListResponse.fromJson(response.body).devices;
    } else {
      final error = jsonDecode(response.error as String);
      final errorDescription = error["error"] as String;
      throw ServerException(errorDescription);
    }
  }

  @override
  Future<List<Device>> unassignDevice({
    required String uuid,
    required String sn,
  }) async {
    final response = await oshApiUserDeviceService.unassignDevice(
      uuid: uuid,
      request: UnassignDeviceRequest(sn: sn),
    );
    if (response.isSuccessful && response.body != null) {
      return DeviceListResponse.fromJson(response.body).devices;
    } else {
      final error = jsonDecode(response.error as String);
      final errorDescription = error["error"] as String;
      throw ServerException(errorDescription);
    }
  }

  @override
  Future<List<Device>> getDeviceList({
    required String uuid,
  }) async {
    final response = await oshApiUserDeviceService.getDeviceList(uuid: uuid);
    if (response.isSuccessful && response.body != null) {
      return DeviceListResponse.fromJson(response.body).devices;
    } else {
      final error = jsonDecode(response.error as String);
      final errorDescription = error["error"] as String;
      throw ServerException(errorDescription);
    }
  }
}
