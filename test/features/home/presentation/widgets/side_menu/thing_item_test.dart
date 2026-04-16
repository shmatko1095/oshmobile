import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' show Either, right;
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/core/theme/theme.dart';
import 'package:oshmobile/features/device_catalog/domain/contracts/device_catalog_sync.dart';
import 'package:oshmobile/features/device_management/domain/models/device_assigned_user.dart';
import 'package:oshmobile/features/device_management/domain/repositories/device_management_repository.dart';
import 'package:oshmobile/features/device_management/domain/usecases/remove_device.dart';
import 'package:oshmobile/features/device_management/domain/usecases/rename_device.dart';
import 'package:oshmobile/features/device_management/presentation/cubit/device_management_cubit.dart';
import 'package:oshmobile/features/home/presentation/widgets/side_menu/thing_item.dart';
import 'package:oshmobile/generated/l10n.dart';
import 'package:oshmobile/init_dependencies.dart';

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

  testWidgets('does not render overflow menu action anymore', (tester) async {
    await _pumpThingItem(tester);

    expect(find.byIcon(Icons.more_horiz_rounded), findsNothing);
  });

  testWidgets('swipe to remove opens same confirm dialog', (tester) async {
    await _pumpThingItem(tester);

    await tester.drag(
      find.byKey(const ValueKey('drawer_device_device-1')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Remove device?'), findsOneWidget);
    expect(find.text('Remove device'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('drawer_device_device-1')), findsOneWidget);
  });
}

Future<void> _pumpThingItem(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.darkTheme,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: const Scaffold(
        body: Center(
          child: SizedBox(
            width: 420,
            child: ThingItem(
              id: 'device-1',
              serial: 'SN-001',
              name: 'Living room thermostat',
              room: 'Living room',
              online: true,
              selected: false,
            ),
          ),
        ),
      ),
    ),
  );

  await tester.pump();
}

class _FakeDeviceManagementRepository implements DeviceManagementRepository {
  @override
  Future<Either<Failure, List<DeviceAssignedUser>>> getDeviceUsers({
    required String serial,
  }) async {
    return right(const <DeviceAssignedUser>[]);
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
