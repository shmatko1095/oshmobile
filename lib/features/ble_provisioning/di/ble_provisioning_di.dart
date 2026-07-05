import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get_it/get_it.dart';
import 'package:oshmobile/core/permissions/ble_permission_service.dart';
import 'package:oshmobile/features/ble_provisioning/data/ble/ble_client.dart';
import 'package:oshmobile/features/ble_provisioning/data/ble/flutter_reactive_ble.dart';
import 'package:oshmobile/features/ble_provisioning/data/crypto/ble_secure_codec.dart';
import 'package:oshmobile/features/ble_provisioning/data/crypto/ble_secure_codec_dev.dart';
import 'package:oshmobile/features/ble_provisioning/data/repositories/ble_provisioning_repository_impl.dart';
import 'package:oshmobile/features/ble_provisioning/domain/repositories/ble_provisioning_repository.dart';
import 'package:oshmobile/features/ble_provisioning/domain/usecases/connect_ble_device.dart';
import 'package:oshmobile/features/ble_provisioning/domain/usecases/connect_wifi_network.dart';
import 'package:oshmobile/features/ble_provisioning/domain/usecases/disconnect_ble_device.dart';
import 'package:oshmobile/features/ble_provisioning/domain/usecases/observe_device_nearby.dart';
import 'package:oshmobile/features/ble_provisioning/domain/usecases/scan_wifi_networks.dart';
import 'package:oshmobile/features/ble_provisioning/presentation/cubit/ble_provisioning_cubit.dart';

void registerBleProvisioningFeature(GetIt locator) {
  locator
    ..registerLazySingleton<BleSecureCodecFactory>(
      () => (secureCode) => DevBleSecureCodec(secureCode),
    )
    ..registerLazySingleton<BlePermissionService>(() => BlePermissionService())
    ..registerLazySingleton<FlutterReactiveBle>(() => FlutterReactiveBle())
    ..registerLazySingleton<BleClient>(() => ReactiveBleClientImpl(locator()))
    ..registerLazySingleton<BleProvisioningRepository>(
      () => BleProvisioningRepositoryImpl(
        locator<BleClient>(),
        locator<BleSecureCodecFactory>(),
      ),
    )
    ..registerLazySingleton(() => ConnectBleDevice(locator()))
    ..registerLazySingleton(() => DisconnectBleDevice(locator()))
    ..registerLazySingleton(() => ScanWifiNetworks(locator()))
    ..registerLazySingleton(() => ConnectWifiNetwork(locator()))
    ..registerLazySingleton(() => ObserveDeviceNearby(locator()))
    ..registerFactory(
      () => BleProvisioningCubit(
        permissions: locator(),
        connectBleDevice: locator(),
        disconnectBleDevice: locator(),
        scanWifiNetworks: locator(),
        connectWifiNetwork: locator(),
        observeDeviceNearby: locator(),
      ),
    );
}