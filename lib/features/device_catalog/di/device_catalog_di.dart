import 'package:get_it/get_it.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_service.dart';
import 'package:oshmobile/features/device_catalog/data/datasources/device_catalog_remote_data_source.dart';
import 'package:oshmobile/features/device_catalog/data/datasources/device_catalog_remote_data_source_impl.dart';
import 'package:oshmobile/features/device_catalog/data/repositories/device_catalog_repository_impl.dart';
import 'package:oshmobile/features/device_catalog/data/selected_device_storage.dart';
import 'package:oshmobile/features/device_catalog/domain/repositories/device_catalog_repository.dart';
import 'package:oshmobile/features/device_catalog/domain/usecases/assign_device.dart';
import 'package:oshmobile/features/device_catalog/domain/usecases/get_devices.dart';
import 'package:oshmobile/features/device_catalog/presentation/cubit/add_device_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void registerDeviceCatalogFeature(GetIt locator) {
  locator
    ..registerFactory<DeviceCatalogRemoteDataSource>(
      () => DeviceCatalogRemoteDataSourceImpl(
        mobileService: locator<MobileV1Service>(),
      ),
    )
    ..registerFactory<DeviceCatalogRepository>(
      () => DeviceCatalogRepositoryImpl(
        dataSource: locator<DeviceCatalogRemoteDataSource>(),
      ),
    )
    ..registerFactory<GetDevices>(
      () => GetDevices(
        deviceCatalogRepository: locator<DeviceCatalogRepository>(),
      ),
    )
    ..registerFactory<AssignDevice>(
      () => AssignDevice(
        deviceCatalogRepository: locator<DeviceCatalogRepository>(),
      ),
    )
    ..registerFactory<SelectedDeviceStorage>(
      () => SelectedDeviceStorage(locator<SharedPreferences>()),
    )
    ..registerFactory<AddDeviceCubit>(
      () => AddDeviceCubit(
        assignDevice: locator<AssignDevice>(),
        deviceCatalogSync: locator(),
      ),
    );
}