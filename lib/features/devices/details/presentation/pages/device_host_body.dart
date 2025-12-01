import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_host_state.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/device_offline_page.dart';
import 'package:oshmobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:oshmobile/features/schedule/presentation/cubit/schedule_cubit.dart';

import '../cubit/device_actions_cubit.dart';
import '../cubit/device_host_cubit.dart';
import '../cubit/device_page_cubit.dart';
import '../cubit/device_state_cubit.dart';
import '../presenters/device_presenter.dart';

final _sl = GetIt.instance;

class DeviceHostBody extends StatelessWidget {
  final Device device;
  final ValueChanged<String?>? onTitleChanged;

  const DeviceHostBody({
    super.key,
    required this.device,
    this.onTitleChanged,
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

  @override
  Widget build(BuildContext context) {
    final liveDevice = context.select((HomeCubit c) {
      try {
        return c.userDevices.firstWhere((d) => d.id == device.id);
      } catch (_) {
        return device;
      }
    });

    return KeyedSubtree(
      key: ValueKey(device.id),
      child: BlocProvider<DeviceHostCubit>(
        create: (ctx) => DeviceHostCubit(
          homeCubit: ctx.read<HomeCubit>(),
          deviceId: device.id,
        ),
        child: MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => _sl<DevicePageCubit>()..load(device.id)),
            BlocProvider(create: (_) => _sl<DeviceStateCubit>()..bind(device.sn)),
            BlocProvider(create: (_) => _sl<DeviceActionsCubit>()..bind(device.sn)),
            BlocProvider(create: (_) => _sl<DeviceScheduleCubit>()..bind(device.sn)),
          ],
          child: BlocBuilder<DeviceHostCubit, DeviceHostState>(
            builder: (context, hostState) {
              if (hostState.isWaitingOnline) {
                return const Center(child: CupertinoActivityIndicator());
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
                      return const Center(child: CupertinoActivityIndicator());
                    case DevicePageError(:final message):
                      return Center(child: Text(message));
                    case DevicePageReady(:final config):
                      {
                        if (liveDevice.connectionInfo.online) {
                          final registry = _sl<DevicePresenterRegistry>();
                          final presenter = registry.resolve(liveDevice.modelId);
                          return presenter.build(context, liveDevice, config);
                        } else {
                          return DeviceOfflinePage(
                            device: liveDevice,
                            onWifiProvisioningSuccess: () {
                              context.read<DeviceHostCubit>().onWifiProvisioningSuccess();
                            },
                          );
                        }
                      }
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
