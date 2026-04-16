import 'package:oshmobile/features/device_management/domain/models/device_assigned_user.dart';

abstract interface class DeviceManagementRemoteDataSource {
  Future<void> renameDevice({
    required String serial,
    required String alias,
    required String description,
  });

  Future<void> removeDevice({
    required String serial,
  });

  Future<List<DeviceAssignedUser>> getDeviceUsers({
    required String serial,
  });
}
