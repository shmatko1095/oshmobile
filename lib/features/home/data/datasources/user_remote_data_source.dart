import 'package:oshmobile/core/common/entities/device/device.dart';

abstract interface class UserRemoteDataSource {
  Future<void> assignDevice({
    required String deviceSn,
    required String deviceSc,
  });

  Future<void> unassignDevice({
    required String serial,
  });

  Future<List<Device>> getDevices();
}
