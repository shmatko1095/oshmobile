import 'package:oshmobile/features/home/domain/entities/user.dart';
import 'package:oshmobile/features/home/domain/entities/user_device.dart';

abstract interface class UserRemoteDataSource {
  Future<void> assignDevice({
    required String userId,
    required String deviceSn,
    required String deviceSc,
  });

  Future<void> unassignDevice({
    required String userId,
    required String deviceId,
  });

  Future<List<UserDevice>> getDevices({
    required String userId,
  });

  Future<User> get({
    required String userId,
  });
}
