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
  final ValueChanged<String?>? onTitleChanged; // <- новый параметр (опционально)

  const DeviceHostBody({
    super.key,
    required this.deviceId,
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
    return null; // для Loading/Error — заголовок не меняем
  }

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
        child: BlocConsumer<DevicePageCubit, DevicePageState>(
          listenWhen: (prev, next) => _titleFrom(prev) != _titleFrom(next),
          listener: (context, state) {
            final t = _titleFrom(state);
            onTitleChanged?.call(t); // или findAncestorStateOfType<HomePageState>()?.setAppBarTitle(t);
          },
          // listenWhen: (prev, next) => _titleFrom(prev) != _titleFrom(next),
          // listener: (context, state) {
          //   final alias = state.device.userData.alias.isEmpty ? device.sn : device.userData.alias;
          //   onTitleChanged?.call(alias);
          //   final title = _titleFrom(state);
          //   onTitleChanged?.call(title);
          // },
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
                  // final alias = device.userData.alias.isEmpty ? device.sn : device.userData.alias;
                  // onTitleChanged?.call(alias);
                  return presenter.build(context, device, config);
                }
            }
          },
        ),
      ),
    );
  }
}
