import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/common/entities/jwt_user_data.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/features/device_management/domain/models/device_assigned_user.dart';
import 'package:oshmobile/features/device_management/domain/repositories/device_management_repository.dart';
import 'package:oshmobile/features/device_management/domain/usecases/get_device_users.dart';
import 'package:oshmobile/features/device_management/presentation/cubit/device_access_cubit.dart';

class _FakeDeviceManagementRepository implements DeviceManagementRepository {
  _FakeDeviceManagementRepository({
    required this.getUsersResult,
  });

  final Either<Failure, List<DeviceAssignedUser>> getUsersResult;
  int getUsersCalls = 0;
  final List<String> requestedSerials = <String>[];

  @override
  Future<Either<Failure, List<DeviceAssignedUser>>> getDeviceUsers({
    required String serial,
  }) async {
    getUsersCalls += 1;
    requestedSerials.add(serial);
    return getUsersResult;
  }

  @override
  Future<Either<Failure, void>> removeDevice({required String serial}) async {
    return right(null);
  }

  @override
  Future<Either<Failure, void>> renameDevice({
    required String serial,
    required String alias,
    required String description,
  }) async {
    return right(null);
  }
}

void main() {
  test('load success sorts users and synthesizes current user when missing',
      () async {
    final repository = _FakeDeviceManagementRepository(
      getUsersResult: right(
        const <DeviceAssignedUser>[
          DeviceAssignedUser(
            uuid: 'u3',
            firstName: 'Zoe',
            lastName: '',
            email: 'zoe@example.com',
          ),
          DeviceAssignedUser(
            uuid: 'u1',
            firstName: 'Alice',
            lastName: 'Taylor',
            email: 'alice@example.com',
          ),
        ],
      ),
    );
    final cubit = DeviceAccessCubit(
      getDeviceUsers: GetDeviceUsers(deviceManagementRepository: repository),
      currentUserResolver: () => JwtUserData(
        uuid: 'u2',
        email: 'me@example.com',
        name: 'My User',
        isAdmin: false,
      ),
    );

    await cubit.load(serial: 'SN-1');

    expect(cubit.state.status, DeviceAccessStatus.ready);
    expect(cubit.state.currentUserUuid, 'u2');
    expect(cubit.state.users.map((u) => u.uuid).toList(), ['u2', 'u1', 'u3']);
    expect(cubit.state.users.first.email, 'me@example.com');

    await cubit.close();
  });

  test('load failure exposes failure status and message', () async {
    final repository = _FakeDeviceManagementRepository(
      getUsersResult: left(Failure.unexpected('boom')),
    );
    final cubit = DeviceAccessCubit(
      getDeviceUsers: GetDeviceUsers(deviceManagementRepository: repository),
      currentUserResolver: () => null,
    );

    await cubit.load(serial: 'SN-2');

    expect(cubit.state.status, DeviceAccessStatus.failure);
    expect(cubit.state.errorMessage, 'boom');

    await cubit.close();
  });

  test('refresh delegates to load and fetches users again', () async {
    final repository = _FakeDeviceManagementRepository(
      getUsersResult: right(const <DeviceAssignedUser>[]),
    );
    final cubit = DeviceAccessCubit(
      getDeviceUsers: GetDeviceUsers(deviceManagementRepository: repository),
      currentUserResolver: () => null,
    );

    await cubit.load(serial: 'SN-3');
    await cubit.refresh(serial: 'SN-3');

    expect(repository.getUsersCalls, 2);
    expect(repository.requestedSerials, ['SN-3', 'SN-3']);

    await cubit.close();
  });
}
