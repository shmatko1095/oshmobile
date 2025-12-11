import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:oshmobile/features/schedule/presentation/cubit/schedule_cubit.dart';
import 'package:oshmobile/features/settings/presentation/cubit/device_settings_cubit.dart';

import '../cubit/device_actions_cubit.dart';
import '../cubit/device_host_cubit.dart';
import '../cubit/device_page_cubit.dart';
import '../cubit/device_state_cubit.dart';
import '../pages/device_host_body.dart';

final _sl = GetIt.instance;

class DeviceHostScope extends StatelessWidget {
  final Device device;
  final ValueChanged<String?>? onTitleChanged;
  final ValueChanged<VoidCallback?>? onSettingsActionChanged;

  const DeviceHostScope({
    super.key,
    required this.device,
    required this.onTitleChanged,
    required this.onSettingsActionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: ValueKey(device.id),
      child: BlocProvider<DeviceHostCubit>(
        create: (ctx) => DeviceHostCubit(
          homeCubit: ctx.read<HomeCubit>(),
          deviceId: device.id,
        ),
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => _sl<DevicePageCubit>()..load(device.id),
            ),
            BlocProvider(
              create: (_) => _sl<DeviceStateCubit>()..bind(device.sn),
            ),
            BlocProvider(
              create: (_) => _sl<DeviceActionsCubit>()..bind(device.sn),
            ),
            BlocProvider(
              create: (_) => _sl<DeviceScheduleCubit>()..bind(device.sn),
            ),
            BlocProvider(
              create: (_) => _sl<DeviceSettingsCubit>()..bind(device.sn),
            ),
          ],
          child: DeviceHostBody(
            deviceId: device.id,
            onTitleChanged: onTitleChanged,
            onSettingsActionChanged: onSettingsActionChanged,
          ),
        ),
      ),
    );
  }
}
