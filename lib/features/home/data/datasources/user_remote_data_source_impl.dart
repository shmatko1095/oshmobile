import 'dart:convert';

import 'package:oshmobile/core/error/exceptions.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api_user/osh_api_user_service.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api_user/requests/assign_device_request.dart';
import 'package:oshmobile/features/home/data/datasources/user_remote_data_source.dart';
import 'package:oshmobile/features/home/domain/entities/user.dart';

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final ApiUserService apiUserService;

  const UserRemoteDataSourceImpl({required this.apiUserService});

  @override
  Future<void> assignDevice({
    required String userId,
    required String deviceSn,
    required String deviceSc,
  }) async {
    final response = await apiUserService.assignDevice(
      userId: userId,
      deviceSn: deviceSn,
      request: AssignDeviceRequest(sc: deviceSc),
    );
    if (!response.isSuccessful) {
      throw ServerException(response.error as String);
    }
  }

  @override
  Future<void> unassignDevice({
    required String userId,
    required String deviceId,
  }) async {
    final response = await apiUserService.unassignDevice(
      userId: userId,
      deviceId: deviceId,
    );
    if (!response.isSuccessful) {
      throw ServerException(response.error as String);
    }
  }

  @override
  Future<User> get({
    required String userId,
  }) async {
    final response = await apiUserService.get(userId: userId);
    if (response.isSuccessful && response.body != null) {
      return User.fromJson(response.body);
    } else {
      final error = jsonDecode(response.error as String);
      final errorDescription = error["error"] as String;
      throw ServerException(errorDescription);
    }
  }
}
