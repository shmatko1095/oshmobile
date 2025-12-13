import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:oshmobile/core/common/widgets/loader.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/core/scopes/device_scope.dart';
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
  VoidCallback? _openSettingsAction;
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

  void _onIconPressed() {
    final homeCubit = context.read<HomeCubit>();
    final state = homeCubit.state;
    final selectedId = state.selectedDeviceId;
    if (selectedId == null) {
      SnackBarUtils.showFail(context: context, content: 'Select a device first.');
      return;
    }

    final device = homeCubit.getDeviceById(selectedId);
    if (device == null) {
      SnackBarUtils.showFail(context: context, content: 'Selected device not found.');
      return;
    }

    if (_openSettingsAction == null) {
      SnackBarUtils.showFail(context: context, content: 'Device view is not ready yet.');
      return;
    }

    _openSettingsAction!.call();
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
            onPressed: _onIconPressed,
          ),
        ],
      ),
      drawer: const SideMenu(),
      body: BlocBuilder<HomeCubit, HomeState>(
        buildWhen: (previous, current) {
          if (previous is HomeReady && current is HomeRefreshing) return false;
          if (previous is HomeRefreshing && current is HomeReady) return false;
          if (previous is HomeReady && current is HomeReady) {
            return previous.selectedDeviceId != current.selectedDeviceId;
          }

          return true;
        },
        builder: (context, state) {
          final homeCubit = context.read<HomeCubit>();

          switch (state) {
            case HomeInitial():
            case HomeLoading():
            case HomeRefreshing():
              _setTitleSafe(null);
              _openSettingsAction = null;
              return const Loader();

            case HomeFailed(:final message):
              _setTitleSafe(null);
              _openSettingsAction = null;
              return Center(child: Text(message ?? ""));

            case HomeReady(:final selectedDeviceId):
              {
                if (selectedDeviceId == null) {
                  _setTitleSafe(null);
                  _openSettingsAction = null;
                  return const NoSelectedDevicePage();
                }

                final device = homeCubit.getDeviceById(selectedDeviceId);

                if (device == null) {
                  _setTitleSafe(null);
                  _openSettingsAction = null;
                  return const NoSelectedDevicePage();
                }

                return DeviceScope(
                  key: ValueKey(device.id),
                  device: device,
                  onTitleChanged: _setTitleSafe,
                  onSettingsActionChanged: (cb) => _openSettingsAction = cb,
                );
              }
          }

          _setTitleSafe(null);
          _openSettingsAction = null;
          return const NoSelectedDevicePage();
        },
      ),
    );
  }
}
