import 'dart:convert';

import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/error/exceptions.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api_device/osh_api_device_service.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api_device/requests/create_device_request.dart';
import 'package:oshmobile/features/home/data/datasources/device_remote_data_source.dart';

class DeviceRemoteDataSourceImpl implements DeviceRemoteDataSource {
  final ApiDeviceService apiDeviceService;

  const DeviceRemoteDataSourceImpl({required this.apiDeviceService});

  @override
  Future<void> create({
    required String serialNumber,
    required String secureCode,
    required String password,
    required String modelId,
  }) async {
    final response = await apiDeviceService.createDevice(
      request: CreateDeviceRequest(
        serialNumber: serialNumber,
        secureCode: secureCode,
        password: password,
        modelId: modelId,
      ),
    );
    if (!response.isSuccessful) {
      throw ServerException(response.error as String);
    }
  }

  @override
  Future<void> delete({
    required String deviceId,
  }) async {
    final response = await apiDeviceService.delete(id: deviceId);
    if (!response.isSuccessful) {
      throw ServerException(response.error as String);
    }
  }

  @override
  Future<Device> get({
    required String deviceId,
  }) async {
    final response = await apiDeviceService.get(id: deviceId);
    if (response.isSuccessful && response.body != null) {
      return Device.fromJson(response.body);
    } else {
      final error = jsonDecode(response.error as String);
      final errorDescription = error["error"] as String;
      throw ServerException(errorDescription);
    }
  }
}
