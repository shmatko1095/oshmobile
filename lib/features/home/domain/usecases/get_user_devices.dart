import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/core/usecase/usecase.dart';
import 'package:oshmobile/features/home/domain/repositories/device_repository.dart';
import 'package:oshmobile/features/home/domain/repositories/user_repository.dart';

class GetUserDevices implements UseCase<List<Device>, String> {
  final UserRepository userRepository;
  final DeviceRepository deviceRepository;

  GetUserDevices({
    required this.userRepository,
    required this.deviceRepository,
  });

  @override
  Future<Either<Failure, List<Device>>> call(String userId) async {
    final userEither = await userRepository.get(userId: userId);
    return await userEither.fold(
      (l) async => left(l),
      (user) async {
        if (user.devices.isEmpty) return right(const []);

        final futures =
            user.devices.map((d) => deviceRepository.get(deviceId: d.id));
        final results = await Future.wait(futures, eagerError: false);

        final devices = <Device>[];
        final errors = <Failure>[];

        for (final r in results) {
          r.fold(errors.add, devices.add);
        }

        if (errors.isNotEmpty) {
          return left(Failure.unexpected(errors.join()));
        }
        return right(devices);
      },
    );
  }
}
