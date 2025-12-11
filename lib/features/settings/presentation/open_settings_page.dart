import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';

import 'package:oshmobile/features/devices/details/presentation/cubit/device_page_cubit.dart';
import 'package:oshmobile/features/settings/presentation/cubit/device_settings_cubit.dart';
import 'package:oshmobile/features/settings/presentation/pages/device_settings_page.dart';

class DeviceSettingsNavigator {
  static void openFromHost(BuildContext hostContext, Device device) {
    if (!hostContext.mounted) return;

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

    final pageState = hostContext.read<DevicePageCubit>().state;

    if (pageState is! DevicePageReady) {
      SnackBarUtils.showFail(
        context: hostContext,
        content: 'Device is not ready yet. Try again in a moment.',
      );
      return;
    }

    final config = pageState.config;

    if (config.settings == null) {
      SnackBarUtils.showFail(
        context: hostContext,
        content: 'This device does not expose any settings.',
      );
      return;
    }

    Navigator.of(hostContext).push(
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
