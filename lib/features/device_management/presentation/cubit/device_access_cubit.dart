import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/entities/jwt_user_data.dart';
import 'package:oshmobile/features/device_management/domain/models/device_assigned_user.dart';
import 'package:oshmobile/features/device_management/domain/usecases/get_device_users.dart';

part 'device_access_state.dart';

typedef CurrentUserResolver = JwtUserData? Function();

class DeviceAccessCubit extends Cubit<DeviceAccessState> {
  final GetDeviceUsers _getDeviceUsers;
  final CurrentUserResolver _currentUserResolver;

  DeviceAccessCubit({
    required GetDeviceUsers getDeviceUsers,
    required CurrentUserResolver currentUserResolver,
  })  : _getDeviceUsers = getDeviceUsers,
        _currentUserResolver = currentUserResolver,
        super(const DeviceAccessState());

  Future<void> load({
    required String serial,
  }) async {
    emit(
      state.copyWith(
        status: DeviceAccessStatus.loading,
        clearError: true,
      ),
    );

    final result = await _getDeviceUsers(GetDeviceUsersParams(serial: serial));
    final currentUser = _currentUserResolver();
    final currentUserUuid = _normalize(currentUser?.uuid);

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: DeviceAccessStatus.failure,
            currentUserUuid: currentUserUuid.isEmpty ? null : currentUserUuid,
            errorMessage: failure.message,
          ),
        );
      },
      (users) {
        emit(
          state.copyWith(
            status: DeviceAccessStatus.ready,
            users: _normalizeUsers(
              users: users,
              currentUser: currentUser,
            ),
            currentUserUuid: currentUserUuid.isEmpty ? null : currentUserUuid,
            clearError: true,
          ),
        );
      },
    );
  }

  Future<void> refresh({
    required String serial,
  }) {
    return load(serial: serial);
  }

  List<DeviceAssignedUser> _normalizeUsers({
    required List<DeviceAssignedUser> users,
    required JwtUserData? currentUser,
  }) {
    final currentUserUuid = _normalize(currentUser?.uuid);
    final byUuid = <String, DeviceAssignedUser>{};

    for (final user in users) {
      final normalizedUuid = _normalize(user.uuid);
      final normalized = DeviceAssignedUser(
        uuid: normalizedUuid,
        firstName: _normalize(user.firstName),
        lastName: _normalize(user.lastName),
        email: _normalize(user.email),
      );
      if (normalizedUuid.isEmpty) {
        continue;
      }
      byUuid[normalizedUuid] = normalized;
    }

    if (currentUser != null && currentUserUuid.isNotEmpty) {
      byUuid.putIfAbsent(
        currentUserUuid,
        () => _syntheticCurrentUser(currentUser),
      );
    }

    final normalizedUsers = byUuid.values.toList(growable: false);
    normalizedUsers.sort(
      (a, b) => _compareUsers(
        a,
        b,
        currentUserUuid: currentUserUuid,
      ),
    );
    return normalizedUsers;
  }

  DeviceAssignedUser _syntheticCurrentUser(JwtUserData currentUser) {
    final name = _normalize(currentUser.name);
    final parts =
        name.isEmpty ? <String>[] : name.split(RegExp(r'\s+')).toList();
    final firstName = parts.isEmpty ? '' : parts.first;
    final lastName = parts.length <= 1 ? '' : parts.skip(1).join(' ');
    return DeviceAssignedUser(
      uuid: _normalize(currentUser.uuid),
      firstName: firstName,
      lastName: lastName,
      email: _normalize(currentUser.email),
    );
  }

  int _compareUsers(
    DeviceAssignedUser a,
    DeviceAssignedUser b, {
    required String currentUserUuid,
  }) {
    final aCurrent = currentUserUuid.isNotEmpty && a.uuid == currentUserUuid;
    final bCurrent = currentUserUuid.isNotEmpty && b.uuid == currentUserUuid;
    if (aCurrent != bCurrent) {
      return aCurrent ? -1 : 1;
    }

    final byName = _displayName(a).compareTo(_displayName(b));
    if (byName != 0) return byName;
    return a.email.toLowerCase().compareTo(b.email.toLowerCase());
  }

  String _displayName(DeviceAssignedUser user) {
    final fullName = _normalize('${user.firstName} ${user.lastName}');
    if (fullName.isNotEmpty) return fullName.toLowerCase();
    if (user.email.isNotEmpty) return user.email.toLowerCase();
    return user.uuid.toLowerCase();
  }

  String _normalize(String? value) {
    return (value ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
