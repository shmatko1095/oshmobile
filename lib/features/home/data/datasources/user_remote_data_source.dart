import 'package:oshmobile/features/home/domain/entities/user.dart';

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

  Future<User> get({
    required String userId,
  });
}
