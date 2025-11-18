import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/features/devices/details/presentation/pages/device_host_body.dart';
import 'package:oshmobile/features/devices/no_selected_device/presentation/pages/no_selected_device_page.dart';
import 'package:oshmobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:oshmobile/features/home/presentation/widgets/mqtt_activity_icon.dart';
import 'package:oshmobile/features/home/presentation/widgets/side_menu/side_menu.dart';

class HomePage extends StatefulWidget {
  static MaterialPageRoute route() => MaterialPageRoute(builder: (_) => const HomePage());

  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _defaultTitle = 'Osh App';
  String? _title;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeCubit>().updateDeviceList();
    });
  }

  void _setTitleSafe(String? t) {
    if (!mounted) return;
    final next = (t == null || t.trim().isEmpty) ? _defaultTitle : t.trim();
    if (_title == next) return;

    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks || phase == SchedulerPhase.transientCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _title = next);
      });
    } else {
      setState(() => _title = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(_title ?? _defaultTitle, overflow: TextOverflow.ellipsis),
        actions: const [
          Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: MqttActivityIcon()),
          IconButton(onPressed: null, icon: Icon(Icons.settings)),
        ],
      ),
      drawer: const SideMenu(),
      body: BlocSelector<HomeCubit, HomeState, String?>(
        selector: (s) => s.selectedDeviceId,
        builder: (context, deviceId) {
          if (deviceId == null || context.read<HomeCubit>().getDeviceById(deviceId) == null) {
            _setTitleSafe(null);
            return const NoSelectedDevicePage();
          } else {
            final device = context.read<HomeCubit>().getDeviceById(deviceId);
            return DeviceHostBody(
              device: device!,
              onTitleChanged: _setTitleSafe,
            );
          }
        },
      ),
    );
  }
}
