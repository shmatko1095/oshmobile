import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/common/entities/jwt_user_data.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/core/theme/theme.dart';
import 'package:oshmobile/features/device_catalog/domain/contracts/device_catalog_sync.dart';
import 'package:oshmobile/features/device_management/domain/models/device_assigned_user.dart';
import 'package:oshmobile/features/device_management/domain/repositories/device_management_repository.dart';
import 'package:oshmobile/features/device_management/domain/usecases/get_device_users.dart';
import 'package:oshmobile/features/device_management/domain/usecases/remove_device.dart';
import 'package:oshmobile/features/device_management/domain/usecases/rename_device.dart';
import 'package:oshmobile/features/device_management/presentation/cubit/device_access_cubit.dart';
import 'package:oshmobile/features/device_management/presentation/cubit/device_management_cubit.dart';
import 'package:oshmobile/features/device_management/presentation/pages/device_access_page.dart';
import 'package:oshmobile/generated/l10n.dart';
import 'package:oshmobile/init_dependencies.dart';

class _FakeDeviceManagementRepository implements DeviceManagementRepository {
  _FakeDeviceManagementRepository({
    this.users = const <DeviceAssignedUser>[],
  });

  final List<DeviceAssignedUser> users;

  @override
  Future<Either<Failure, List<DeviceAssignedUser>>> getDeviceUsers({
    required String serial,
  }) async {
    return right(users);
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

class _FakeDeviceCatalogSync implements DeviceCatalogSync {
  @override
  void onDeviceRemoved(String deviceId) {}

  @override
  Future<void> refresh() async {}
}

void main() {
  setUp(() {
    locator.allowReassignment = true;
    locator.registerFactory<DeviceManagementCubit>(
      () => DeviceManagementCubit(
        renameDevice: RenameDevice(
          deviceManagementRepository: _FakeDeviceManagementRepository(),
        ),
        removeDevice: RemoveDevice(
          deviceManagementRepository: _FakeDeviceManagementRepository(),
        ),
        deviceCatalogSync: _FakeDeviceCatalogSync(),
      ),
    );
  });

  tearDown(() async {
    await locator.reset();
  });

  testWidgets('shows delete icon only for current user row', (tester) async {
    final cubit = DeviceAccessCubit(
      getDeviceUsers: GetDeviceUsers(
        deviceManagementRepository: _FakeDeviceManagementRepository(
          users: const <DeviceAssignedUser>[
            DeviceAssignedUser(
              uuid: 'u2',
              firstName: 'My',
              lastName: 'User',
              email: 'me@example.com',
            ),
            DeviceAssignedUser(
              uuid: 'u1',
              firstName: 'Alice',
              lastName: 'Taylor',
              email: 'alice@example.com',
            ),
          ],
        ),
      ),
      currentUserResolver: () => JwtUserData(
        uuid: 'u2',
        email: 'me@example.com',
        name: 'My User',
        isAdmin: false,
      ),
    );

    await cubit.load(serial: 'SN-1');

    await tester.pumpWidget(
      _buildApp(
        BlocProvider<DeviceAccessCubit>.value(
          value: cubit,
          child: const DeviceAccessPage(
            deviceId: 'device-1',
            deviceSerial: 'SN-1',
            deviceName: 'Living room thermostat',
            isDemoMode: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('You'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('device_access_remove_u2')), findsOneWidget);
    expect(find.byKey(const ValueKey('device_access_remove_u1')), findsNothing);

    await cubit.close();
  });

  testWidgets('confirming self-remove pops to root route', (tester) async {
    final cubit = DeviceAccessCubit(
      getDeviceUsers: GetDeviceUsers(
        deviceManagementRepository: _FakeDeviceManagementRepository(
          users: const <DeviceAssignedUser>[
            DeviceAssignedUser(
              uuid: 'u2',
              firstName: 'My',
              lastName: 'User',
              email: 'me@example.com',
            ),
          ],
        ),
      ),
      currentUserResolver: () => JwtUserData(
        uuid: 'u2',
        email: 'me@example.com',
        name: 'My User',
        isAdmin: false,
      ),
    );
    await cubit.load(serial: 'SN-1');

    await tester.pumpWidget(
      _buildApp(
        _PushAccessPageHarness(cubit: cubit),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('root'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('open_access_page')));
    await tester.pumpAndSettle();
    expect(find.text('Device access'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('device_access_remove_u2')));
    await tester.pumpAndSettle();
    expect(find.text('Remove device?'), findsOneWidget);

    await tester.tap(find.text('Remove device'));
    await tester.pumpAndSettle();

    expect(find.text('root'), findsOneWidget);
    expect(find.text('Device access'), findsNothing);

    await cubit.close();
  });
}

Widget _buildApp(Widget home) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: home,
  );
}

class _PushAccessPageHarness extends StatelessWidget {
  const _PushAccessPageHarness({
    required this.cubit,
  });

  final DeviceAccessCubit cubit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('root'),
            TextButton(
              key: const ValueKey('open_access_page'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => BlocProvider<DeviceAccessCubit>.value(
                      value: cubit,
                      child: const DeviceAccessPage(
                        deviceId: 'device-1',
                        deviceSerial: 'SN-1',
                        deviceName: 'Living room thermostat',
                        isDemoMode: false,
                      ),
                    ),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ],
        ),
      ),
    );
  }
}
