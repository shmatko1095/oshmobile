import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/error/failures.dart';

abstract interface class DeviceRepository {
  Future<Either<Failure, Device>> get({
    required String serial,
  });
}
