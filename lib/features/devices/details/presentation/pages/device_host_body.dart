import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../cubit/device_actions_cubit.dart';
import '../cubit/device_page_cubit.dart';
import '../cubit/device_state_cubit.dart';
import '../presenters/device_presenter.dart';

final _sl = GetIt.instance;

class DeviceHostBody extends StatelessWidget {
  final String deviceId;

  const DeviceHostBody({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: ValueKey(deviceId),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => _sl<DevicePageCubit>()..load(deviceId)),
          BlocProvider(create: (_) => _sl<DeviceStateCubit>()..bindDevice(deviceId)),
          BlocProvider(create: (_) => _sl<DeviceActionsCubit>()),
        ],
        child: BlocBuilder<DevicePageCubit, DevicePageState>(
          builder: (context, st) {
            switch (st) {
              case DevicePageLoading():
                return const Center(child: CupertinoActivityIndicator());
              case DevicePageError(:final message):
                return Center(child: Text(message));
              case DevicePageReady(:final device, :final config):
                {
                  final registry = _sl<DevicePresenterRegistry>();
                  final presenter = registry.resolve(device.modelId);
                  return presenter.build(context, device, config);
                }
            }
          },
        ),
      ),
    );
  }
}
