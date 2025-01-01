import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/error/failures.dart';

abstract interface class OshRepository {
  Future<Either<Failure, void>> assignDevice({
    required String uuid,
    required String sn,
    required String sc,
  });

  Future<Either<Failure, void>> unassignDevice({
    required String uuid,
    required String sn,
  });

  Future<Either<Failure, void>> getDeviceList({
    required String uuid,
  });
}
