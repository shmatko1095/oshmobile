import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/features/devices/details/domain/queries/get_device_full.dart';
import 'package:oshmobile/features/devices/details/presentation/models/osh_config.dart';
import 'package:oshmobile/features/settings/presentation/cubit/device_settings_cubit.dart';
import 'package:oshmobile/features/settings/presentation/pages/device_settings_page.dart';

final _sl = GetIt.instance;

/// Centralized navigation entrypoint for Device Settings.
///
/// Открывает экран настроек, используя:
/// - уже существующий DeviceSettingsCubit из hostContext (DeviceHostBody),
/// - Device переданный снаружи (из HomeCubit),
/// - DeviceConfig, загруженный через GetDeviceFull.
class DeviceSettingsNavigator {
  static Future<void> openFromHost(
    BuildContext hostContext,
    Device device,
  ) async {
    // 1) Берём уже привязанный DeviceSettingsCubit из поддерева DeviceHostBody.
    DeviceSettingsCubit settingsCubit;
    try {
      settingsCubit = hostContext.read<DeviceSettingsCubit>();
    } catch (_) {
      SnackBarUtils.showFail(
        context: hostContext,
        content: 'Settings cubit is not available in the widget tree.',
      );
      return;
    }

    // 2) Грузим конфиг девайса через тот же use-case, что и DevicePageCubit.
    final getDeviceFull = _sl<GetDeviceFull>();
    DeviceConfig config;

    try {
      final full = await getDeviceFull(device.id);
      final rawCfg = full.configuration['osh-config'] as Map<String, dynamic>? ?? full.configuration;
      config = DeviceConfig.fromJson(rawCfg);
    } catch (e) {
      SnackBarUtils.showFail(
        context: hostContext,
        content: 'Failed to load device configuration: $e',
      );
      return;
    }

    if (config.settings == null) {
      SnackBarUtils.showFail(
        context: hostContext,
        content: 'This device does not expose any settings.',
      );
      return;
    }

    // 3) Открываем страницу, реиспользуя уже живой кубит.
    await Navigator.of(hostContext).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: settingsCubit,
          child: DeviceSettingsPage(
            device: device,
            config: config,
          ),
        ),
      ),
    );
  }
}
