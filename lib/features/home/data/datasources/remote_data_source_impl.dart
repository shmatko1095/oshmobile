import 'dart:convert';

import 'package:oshmobile/core/error/exceptions.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api_device/osh_api_user_device_service.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api_device/requests/assign_device_request.dart';
import 'package:oshmobile/features/home/data/datasources/remote_data_source.dart';

class OshRemoteDataSourceImpl implements OshRemoteDataSource {
  final OshApiUserDeviceService oshApiUserDeviceService;

  OshRemoteDataSourceImpl({required this.oshApiUserDeviceService});

  @override
  Future<void> assignDevice({
    required String uuid,
    required String sn,
    required String sc,
  }) async {
    final response = await oshApiUserDeviceService.assignDevice(
      uuid: uuid,
      request: AssignDeviceRequest(sn: sn, sc: sc),
    );

    if (response.isSuccessful && response.body != null) {
      // return Session.fromJson(response.body);
    } else {
      final error = jsonDecode(response.error as String);
      final errorDescription = error["error_description"] as String;
      throw ServerException(errorDescription);
    }
  }

  @override
  Future<void> unassignDevice({
    required String uuid,
    required String sn,
  }) async {}

  @override
  Future<void> getDeviceList({
    required String uuid,
  }) async {}
}
