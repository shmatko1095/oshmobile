import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';

import 'package:oshmobile/features/devices/details/presentation/cubit/device_page_cubit.dart';
import 'package:oshmobile/features/device_about/presentation/cubit/device_about_cubit.dart';
import 'package:oshmobile/features/settings/presentation/cubit/device_settings_cubit.dart';
import 'package:oshmobile/features/settings/presentation/pages/device_settings_page.dart';

class DeviceSettingsNavigator {
  static void openFromHost(BuildContext hostContext, Device device) {
    if (!hostContext.mounted) return;

    DeviceSettingsCubit settingsCubit;
    DeviceAboutCubit aboutCubit;
    try {
      settingsCubit = hostContext.read<DeviceSettingsCubit>();
      aboutCubit = hostContext.read<DeviceAboutCubit>();
    } catch (_) {
      SnackBarUtils.showFail(
        context: hostContext,
        content: 'Settings/about cubit is not available in the widget tree.',
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

    // Ensure settings are actively fetched when opening the screen.
    unawaited(settingsCubit.refresh(forceGet: true));

    Navigator.of(hostContext).push(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: settingsCubit),
            BlocProvider.value(value: aboutCubit),
          ],
          child: DeviceSettingsPage(
            device: device,
            config: config,
          ),
        ),
      ),
    );
  }
}
