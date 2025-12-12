import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/cubits/mqtt/global_mqtt_cubit.dart';
import 'package:oshmobile/core/common/cubits/mqtt/mqtt_comm_cubit.dart';
import 'package:oshmobile/core/common/widgets/session_mqtt_coordinator.dart';
import 'package:oshmobile/core/network/mqtt/device_mqtt_repo.dart';
import 'package:oshmobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:oshmobile/init_dependencies.dart';

/// Session composition root.
/// Creates session-scoped dependencies and provides them to the subtree.
class SessionScope extends StatelessWidget {
  final Widget child;

  const SessionScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<DeviceMqttRepo>(
      create: (_) => locator<DeviceMqttRepo>(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider<HomeCubit>(
            create: (_) => locator<HomeCubit>(),
          ),
          BlocProvider<GlobalMqttCubit>(
            create: (ctx) => GlobalMqttCubit(mqttRepo: ctx.read<DeviceMqttRepo>()),
          ),
          BlocProvider<MqttCommCubit>(
            create: (_) => locator<MqttCommCubit>(),
          ),
        ],
        child: SessionMqttCoordinator(child: child),
      ),
    );
  }
}
