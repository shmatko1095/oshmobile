import 'package:get_it/get_it.dart';
import 'package:oshmobile/core/common/cubits/auth/global_auth_cubit.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_service.dart';
import 'package:oshmobile/features/device_management/data/datasources/device_management_remote_data_source.dart';
import 'package:oshmobile/features/device_management/data/datasources/device_management_remote_data_source_impl.dart';
import 'package:oshmobile/features/device_management/data/repositories/device_management_repository_impl.dart';
import 'package:oshmobile/features/device_management/domain/repositories/device_management_repository.dart';
import 'package:oshmobile/features/device_management/domain/usecases/get_device_users.dart';
import 'package:oshmobile/features/device_management/domain/usecases/remove_device.dart';
import 'package:oshmobile/features/device_management/domain/usecases/rename_device.dart';
import 'package:oshmobile/features/device_management/presentation/cubit/device_access_cubit.dart';
import 'package:oshmobile/features/device_management/presentation/cubit/device_management_cubit.dart';

void registerDeviceManagementFeature(GetIt locator) {
  locator
    ..registerFactory<DeviceManagementRemoteDataSource>(
      () => DeviceManagementRemoteDataSourceImpl(
        mobileService: locator<MobileV1Service>(),
      ),
    )
    ..registerFactory<DeviceManagementRepository>(
      () => DeviceManagementRepositoryImpl(
        dataSource: locator<DeviceManagementRemoteDataSource>(),
      ),
    )
    ..registerFactory<RenameDevice>(
      () => RenameDevice(
        deviceManagementRepository: locator<DeviceManagementRepository>(),
      ),
    )
    ..registerFactory<RemoveDevice>(
      () => RemoveDevice(
        deviceManagementRepository: locator<DeviceManagementRepository>(),
      ),
    )
    ..registerFactory<GetDeviceUsers>(
      () => GetDeviceUsers(
        deviceManagementRepository: locator<DeviceManagementRepository>(),
      ),
    )
    ..registerFactory<DeviceManagementCubit>(
      () => DeviceManagementCubit(
        renameDevice: locator<RenameDevice>(),
        removeDevice: locator<RemoveDevice>(),
        deviceCatalogSync: locator(),
      ),
    )
    ..registerFactory<DeviceAccessCubit>(
      () => DeviceAccessCubit(
        getDeviceUsers: locator<GetDeviceUsers>(),
        currentUserResolver: locator<GlobalAuthCubit>().getJwtUserData,
      ),
    );
}