import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/features/home/domain/entities/user.dart';
import 'package:oshmobile/features/home/domain/entities/user_device.dart';

abstract interface class UserRepository {
  Future<Either<Failure, void>> assignDevice({
    required String userId,
    required String deviceSn,
    required String deviceSc,
  });

  Future<Either<Failure, void>> unassignDevice({
    required String userId,
    required String deviceId,
  });

  Future<Either<Failure, List<UserDevice>>> getDevices({
    required String userId,
  });

  Future<Either<Failure, User>> get({
    required String userId,
  });
}
