import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/widgets/loader.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/features/devices/details/presentation/pages/device_host_body.dart';
import 'package:oshmobile/features/devices/no_selected_device/presentation/pages/no_selected_device_page.dart';
import 'package:oshmobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:oshmobile/features/home/presentation/widgets/mqtt_activity_icon.dart';
import 'package:oshmobile/features/home/presentation/widgets/side_menu/side_menu.dart';
import 'package:oshmobile/features/settings/presentation/open_settings_page.dart';

class HomePage extends StatefulWidget {
  static MaterialPageRoute route() => MaterialPageRoute(builder: (_) => const HomePage());

  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _defaultTitle = 'Osh App';
  String? _title;
  final GlobalKey _deviceHostInnerKey = GlobalKey();

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
        actions: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: MqttActivityIcon(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              final homeCubit = context.read<HomeCubit>();
              final state = homeCubit.state;
              final selectedId = state.selectedDeviceId;
              if (selectedId == null) {
                SnackBarUtils.showFail(
                  context: context,
                  content: 'Select a device first.',
                );
                return;
              }

              final device = homeCubit.getDeviceById(selectedId);
              if (device == null) {
                SnackBarUtils.showFail(
                  context: context,
                  content: 'Selected device not found.',
                );
                return;
              }

              final hostCtx = _deviceHostInnerKey.currentContext;
              if (hostCtx == null) {
                // DeviceHostBody ещё не построен (или мы на экране без девайса).
                SnackBarUtils.showFail(
                  context: context,
                  content: 'Device view is not ready yet.',
                );
                return;
              }

              DeviceSettingsNavigator.openFromHost(hostCtx, device);
            },
          ),
        ],
      ),
      drawer: const SideMenu(),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          final homeCubit = context.read<HomeCubit>();

          switch (state) {
            case HomeInitial():
            case HomeLoading():
              _setTitleSafe(null);
              return const Loader();

            case HomeFailed(:final message):
              _setTitleSafe(null);
              return Center(child: Text(message ?? ""));

            case HomeReady(:final selectedDeviceId):
              {
                if (selectedDeviceId == null) {
                  _setTitleSafe(null);
                  return const NoSelectedDevicePage();
                }

                final device = homeCubit.getDeviceById(selectedDeviceId);

                if (device == null) {
                  _setTitleSafe(null);
                  return const NoSelectedDevicePage();
                }

                return DeviceHostBody(
                  device: device,
                  onTitleChanged: _setTitleSafe,
                  settingsHostKey: _deviceHostInnerKey,
                );
              }
          }

          _setTitleSafe(null);
          return const NoSelectedDevicePage();
        },
      ),
    );
  }
}
