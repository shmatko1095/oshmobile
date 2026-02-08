import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/common/widgets/loader.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_host_state.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/device_offline_page.dart';
import 'package:oshmobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:oshmobile/features/schedule/presentation/cubit/schedule_cubit.dart';
import 'package:oshmobile/features/settings/presentation/open_settings_page.dart';
import 'package:oshmobile/features/settings/presentation/cubit/device_settings_cubit.dart';

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
    final futures = <Future<void>>[];
    futures.add(context.read<DeviceScheduleCubit>().refresh(forceGet: true));
    futures.add(context.read<DeviceSettingsCubit>().refresh(forceGet: true));
    await Future.wait(futures.map((f) => f.catchError((_) {})));
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

    if (liveDevice == null) return const Loader();

    return Builder(
      builder: (innerCtx) {
        if (onSettingsActionChanged != null) {
          onSettingsActionChanged!(() => DeviceSettingsNavigator.openFromHost(innerCtx, liveDevice));
        }

        return BlocBuilder<DeviceHostCubit, DeviceHostState>(
          builder: (context, hostState) {
            if (hostState.isWaitingOnline) {
              return const Loader();
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
                    return const Loader();

                  case DevicePageError(:final message):
                    return Center(child: Text(message));

                  case DevicePageReady(:final config):
                    {
                      if (!liveDevice.connectionInfo.online) {
                        return DeviceOfflinePage(
                          device: liveDevice,
                          onWifiProvisioningSuccess: () {
                            context.read<DeviceHostCubit>().onWifiProvisioningSuccess();
                          },
                        );
                      }

                      final presenter = presenters.resolve(liveDevice.modelId);
                      return RefreshIndicator(
                        onRefresh: () => _refreshAll(context),
                        child: presenter.build(context, liveDevice, config),
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
