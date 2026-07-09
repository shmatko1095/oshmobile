import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:keycloak_wrapper/keycloak_wrapper.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/selected_device_session_cubit.dart';
import 'package:oshmobile/core/analytics/osh_analytics.dart';
import 'package:oshmobile/core/common/cubits/auth/global_auth_cubit.dart';
import 'package:oshmobile/core/common/cubits/mqtt/mqtt_comm_cubit.dart';
import 'package:oshmobile/core/common/entities/device/connection_info.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/common/entities/device/device_user_data.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/core/network/chopper_client/auth/auth_service.dart';
import 'package:oshmobile/core/network/chopper_client/core/session_storage.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_service.dart';
import 'package:oshmobile/core/permissions/ble_permission_service.dart';
import 'package:oshmobile/core/theme/theme.dart';
import 'package:oshmobile/features/ble_provisioning/domain/entities/wifi_connect_status.dart';
import 'package:oshmobile/features/ble_provisioning/domain/entities/wifi_network.dart';
import 'package:oshmobile/features/ble_provisioning/domain/repositories/ble_provisioning_repository.dart';
import 'package:oshmobile/features/ble_provisioning/domain/usecases/connect_ble_device.dart';
import 'package:oshmobile/features/ble_provisioning/domain/usecases/connect_wifi_network.dart';
import 'package:oshmobile/features/ble_provisioning/domain/usecases/disconnect_ble_device.dart';
import 'package:oshmobile/features/ble_provisioning/domain/usecases/observe_device_nearby.dart';
import 'package:oshmobile/features/ble_provisioning/domain/usecases/scan_wifi_networks.dart';
import 'package:oshmobile/features/ble_provisioning/presentation/cubit/ble_provisioning_cubit.dart';
import 'package:oshmobile/features/ble_provisioning/presentation/pages/ble_wifi_provisioning_entry_page.dart';
import 'package:oshmobile/features/device_catalog/data/selected_device_storage.dart';
import 'package:oshmobile/features/device_catalog/domain/repositories/device_catalog_repository.dart';
import 'package:oshmobile/features/device_catalog/domain/usecases/get_devices.dart';
import 'package:oshmobile/features/device_catalog/presentation/cubit/device_catalog_cubit.dart';
import 'package:oshmobile/features/device_management/presentation/pages/device_settings_hub_page.dart';
import 'package:oshmobile/generated/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    OshAnalytics.debugSetBackend(const _NoopAnalyticsBackend());
  });

  tearDown(() {
    OshAnalytics.debugResetBackend();
  });

  testWidgets('shows add Wi-Fi action and opens helper page', (tester) async {
    final catalogCubit = await _createCatalogCubit(
      device: _device(serial: 'SN-1'),
    );
    final sessionCubit = SelectedDeviceSessionCubit();
    addTearDown(catalogCubit.close);
    addTearDown(sessionCubit.close);

    await tester.pumpWidget(
      _buildSettingsHubApp(
        catalogCubit: catalogCubit,
        sessionCubit: sessionCubit,
      ),
    );
    await tester.pump();

    expect(find.text('Додати Wi‑Fi мережу'), findsOneWidget);

    await tester.tap(find.text('Додати Wi‑Fi мережу'));
    await tester.pumpAndSettle();

    expect(find.byType(BleWifiProvisioningEntryPage), findsOneWidget);
    expect(find.text('Почати пошук'), findsOneWidget);
  });

  testWidgets('disables add Wi-Fi action without serial', (tester) async {
    final catalogCubit = await _createCatalogCubit(
      device: _device(serial: ''),
    );
    final sessionCubit = SelectedDeviceSessionCubit();
    addTearDown(catalogCubit.close);
    addTearDown(sessionCubit.close);

    await tester.pumpWidget(
      _buildSettingsHubApp(
        catalogCubit: catalogCubit,
        sessionCubit: sessionCubit,
      ),
    );
    await tester.pump();

    expect(find.text('Додати Wi‑Fi мережу'), findsOneWidget);
    expect(
      find.text(
        'Налаштування Wi‑Fi недоступне, бо у пристрою немає серійного номера.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Додати Wi‑Fi мережу'));
    await tester.pumpAndSettle();

    expect(find.byType(BleWifiProvisioningEntryPage), findsNothing);
  });

  testWidgets('helper page shows instruction and start action', (tester) async {
    await tester.pumpWidget(
      _buildLocalizedApp(
        home: BleWifiProvisioningEntryPage(
          deviceSn: 'SN-1',
          createCubit: _createBleProvisioningCubit,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Додати Wi‑Fi мережу'), findsWidgets);
    expect(
      find.text(
        'Увімкніть налаштування Wi‑Fi через BLE на пристрої та тримайте телефон поруч, щоб знайти доступні мережі.',
      ),
      findsOneWidget,
    );
    expect(find.text('Почати пошук'), findsOneWidget);
  });
}

Future<_TestDeviceCatalogCubit> _createCatalogCubit({
  required Device device,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  return _TestDeviceCatalogCubit(
    device: device,
    prefs: prefs,
  );
}

Widget _buildSettingsHubApp({
  required DeviceCatalogCubit catalogCubit,
  required SelectedDeviceSessionCubit sessionCubit,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<DeviceCatalogCubit>.value(value: catalogCubit),
      BlocProvider<SelectedDeviceSessionCubit>.value(value: sessionCubit),
    ],
    child: _buildLocalizedApp(
      home: const DeviceSettingsHubPage(
        deviceId: 'device-1',
        createBleProvisioningCubit: _createBleProvisioningCubit,
      ),
    ),
  );
}

Widget _buildLocalizedApp({required Widget home}) {
  return MaterialApp(
    locale: const Locale('uk'),
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

Device _device({required String serial}) {
  return Device(
    id: 'device-1',
    sn: serial,
    modelId: 'thermostat',
    modelName: 'Thermostat',
    userData: const DeviceUserData(
      alias: 'Living room',
      description: '',
    ),
    connectionInfo: ConnectionInfo(online: true),
  );
}

class _TestDeviceCatalogCubit extends DeviceCatalogCubit {
  _TestDeviceCatalogCubit._({
    required Device device,
    required SharedPreferences prefs,
    required GlobalAuthCubit authCubit,
    required MqttCommCubit commCubit,
  })  : _authCubit = authCubit,
        _commCubit = commCubit,
        super(
          globalAuthCubit: authCubit,
          getDevices: GetDevices(
            deviceCatalogRepository: _FakeDeviceCatalogRepository([device]),
          ),
          selectedDeviceStorage: SelectedDeviceStorage(prefs),
          comm: commCubit,
        ) {
    emit(
      DeviceCatalogState(
        status: DeviceCatalogStatus.ready,
        devices: [device],
        selectedDeviceId: device.id,
      ),
    );
  }

  factory _TestDeviceCatalogCubit({
    required Device device,
    required SharedPreferences prefs,
  }) {
    return _TestDeviceCatalogCubit._(
      device: device,
      prefs: prefs,
      authCubit: _TestGlobalAuthCubit(),
      commCubit: MqttCommCubit(),
    );
  }

  final GlobalAuthCubit _authCubit;
  final MqttCommCubit _commCubit;

  @override
  Future<void> close() async {
    await _commCubit.close();
    await _authCubit.close();
    return super.close();
  }
}

class _TestGlobalAuthCubit extends GlobalAuthCubit {
  _TestGlobalAuthCubit()
      : super(
          authService: AuthService.create(),
          mobileService: MobileV1Service.create(),
          sessionStorage: SessionStorage(
            storage: const FlutterSecureStorage(),
          ),
          keycloakWrapper: KeycloakWrapper(),
        );
}

class _FakeDeviceCatalogRepository implements DeviceCatalogRepository {
  const _FakeDeviceCatalogRepository(this.devices);

  final List<Device> devices;

  @override
  Future<Either<Failure, void>> assignDevice({
    required String deviceSn,
    required String deviceSc,
  }) async {
    return right(null);
  }

  @override
  Future<Either<Failure, List<Device>>> getDevices() async {
    return right(devices);
  }
}

BleProvisioningCubit _createBleProvisioningCubit() {
  final repo = _FakeBleProvisioningRepository();
  return BleProvisioningCubit(
    permissions: _FakeBlePermissionService(),
    connectBleDevice: ConnectBleDevice(repo),
    disconnectBleDevice: DisconnectBleDevice(repo),
    scanWifiNetworks: ScanWifiNetworks(repo),
    connectWifiNetwork: ConnectWifiNetwork(repo),
    observeDeviceNearby: ObserveDeviceNearby(repo),
  );
}

class _FakeBlePermissionService extends BlePermissionService {
  @override
  Future<bool> ensureBlePermissions() async => true;
}

class _FakeBleProvisioningRepository implements BleProvisioningRepository {
  @override
  Future<void> connectToDevice({
    required String serialNumber,
    required String secureCode,
    Duration timeout = const Duration(seconds: 10),
  }) async {}

  @override
  Future<void> disconnect() async {}

  @override
  Stream<List<WifiNetwork>> scanWifiNetworks({Duration? timeout}) {
    return const Stream<List<WifiNetwork>>.empty();
  }

  @override
  Stream<WifiConnectStatus> connectToWifi({
    required String ssid,
    required String password,
    Duration? timeout,
  }) {
    return const Stream<WifiConnectStatus>.empty();
  }

  @override
  Stream<bool> observeDeviceNearby({required String serialNumber}) {
    return Stream<bool>.value(true);
  }
}

class _NoopAnalyticsBackend implements AnalyticsBackend {
  const _NoopAnalyticsBackend();

  @override
  Future<void> logEvent(
    String name, {
    Map<String, Object?>? parameters,
  }) async {}

  @override
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
    Map<String, Object?>? parameters,
  }) async {}

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setUserId(String? userId) async {}

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {}
}
