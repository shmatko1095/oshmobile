import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/common/widgets/loader.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_host_state.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/device_compatibility_state_page.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/device_offline_page.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:oshmobile/features/settings/presentation/open_settings_page.dart';

import '../cubit/device_host_cubit.dart';
import '../cubit/device_page_cubit.dart';
import '../presenters/device_presenter.dart';

class DeviceHostBody extends StatelessWidget {
  final String deviceId;
  final DevicePresenterRegistry presenters;
  final ValueChanged<String?>? onTitleChanged;
  final ValueChanged<VoidCallback?>? onSettingsActionChanged;

  const DeviceHostBody({
    super.key,
    required this.deviceId,
    required this.presenters,
    required this.onTitleChanged,
    required this.onSettingsActionChanged,
  });

  String? _titleFrom(DevicePageState s) {
    if (s is DevicePageReady) {
      String take(String v) => v.trim();
      final alias = take(s.device.userData.alias);
      if (alias.isNotEmpty) return alias;

      final sn = take(s.device.sn);
      if (sn.isNotEmpty) return sn;

      final model = take(s.device.modelId);
      if (model.isNotEmpty) return model;

      final id = take(s.device.id);
      if (id.isNotEmpty) return id;
    }
    return null;
  }

  Future<void> _refreshAll(BuildContext context) async {
    try {
      await context.read<DeviceFacade>().refreshAll(forceGet: true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final Device? liveDevice = context.select((HomeCubit c) {
      try {
        return c.userDevices.firstWhere((d) => d.id == deviceId);
      } catch (_) {
        return null;
      }
    });

    if (liveDevice == null) {
      onSettingsActionChanged?.call(null);
      return const Loader();
    }

    return Builder(
      builder: (innerCtx) {
        return BlocBuilder<DeviceHostCubit, DeviceHostState>(
          builder: (context, hostState) {
            if (hostState.isWaitingOnline) {
              onSettingsActionChanged?.call(null);
              return const Loader();
            }

            // For offline devices show offline screen immediately.
            if (!liveDevice.connectionInfo.online) {
              onSettingsActionChanged?.call(null);
              return DeviceOfflinePage(
                device: liveDevice,
                onWifiProvisioningSuccess: () {
                  context.read<DeviceHostCubit>().onWifiProvisioningSuccess();
                },
              );
            }

            return BlocConsumer<DevicePageCubit, DevicePageState>(
              listenWhen: (prev, next) => _titleFrom(prev) != _titleFrom(next),
              listener: (context, state) {
                final t = _titleFrom(state);
                onTitleChanged?.call(t);
              },
              builder: (context, st) {
                switch (st) {
                  case DevicePageLoading():
                    onSettingsActionChanged?.call(null);
                    return const Loader();

                  case DevicePageError(:final message):
                    onSettingsActionChanged?.call(null);
                    return Center(child: Text(message));

                  case DevicePageUpdateRequired(:final message):
                    onSettingsActionChanged?.call(null);
                    return DeviceCompatibilityStatePage(
                      device: liveDevice,
                      variant: DeviceCompatibilityVariant.updateRequired,
                      details: message,
                      onRetry: () =>
                          context.read<DevicePageCubit>().load(deviceId),
                    );

                  case DevicePageCompatibilityError(:final message):
                    onSettingsActionChanged?.call(null);
                    return DeviceCompatibilityStatePage(
                      device: liveDevice,
                      variant: DeviceCompatibilityVariant.compatibilityError,
                      details: message,
                      onRetry: () =>
                          context.read<DevicePageCubit>().load(deviceId),
                    );

                  case DevicePageReady(:final bundle):
                    {
                      onSettingsActionChanged?.call(
                        () => DeviceSettingsNavigator.openFromHost(
                          innerCtx,
                          liveDevice,
                        ),
                      );
                      final presenter = presenters.resolve(bundle.modelId);
                      return RefreshIndicator(
                        onRefresh: () => _refreshAll(context),
                        child: presenter.build(context, liveDevice, bundle),
                      );
                    }
                }
              },
            );
          },
        );
      },
    );
  }
}
