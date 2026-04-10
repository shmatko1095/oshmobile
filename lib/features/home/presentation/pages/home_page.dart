import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:oshmobile/core/analytics/osh_analytics_screen_view.dart';
import 'package:oshmobile/core/analytics/osh_analytics_screens.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/common/widgets/loader.dart';
import 'package:oshmobile/app/device_session/scopes/device_scope.dart';
import 'package:oshmobile/features/devices/no_selected_device/presentation/pages/no_selected_device_page.dart';
import 'package:oshmobile/features/home/presentation/pages/add_device_page.dart';
import 'package:oshmobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:oshmobile/features/home/presentation/widgets/mqtt_activity_icon.dart';
import 'package:oshmobile/features/home/presentation/widgets/side_menu/side_menu.dart';
import 'package:oshmobile/generated/l10n.dart';

class HomePage extends StatefulWidget {
  static MaterialPageRoute route() =>
      MaterialPageRoute(builder: (_) => const HomePage());

  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _defaultTitle = 'Osh App';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.transientCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _title = next);
      });
    } else {
      setState(() => _title = next);
    }
  }

  void _setSettingsActionSafe(VoidCallback? cb) {
    if (!mounted) return;
    final shouldRebuild = (_openSettingsAction == null) != (cb == null);
    if (!shouldRebuild) {
      _openSettingsAction = cb;
      return;
    }

    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.transientCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _openSettingsAction = cb);
        }
      });
    } else {
      setState(() => _openSettingsAction = cb);
    }
  }

  bool _canOpenSettings(HomeCubit homeCubit, HomeState state) {
    if (_openSettingsAction == null) return false;
    if (state is HomeInitial ||
        state is HomeLoading ||
        state is HomeRefreshing) {
      return false;
    }

    final selectedId = state.selectedDeviceId;
    if (selectedId == null) return false;

    return homeCubit.getDeviceById(selectedId) != null;
  }

  void _onIconPressed() {
    final homeCubit = context.read<HomeCubit>();
    final state = homeCubit.state;
    if (!_canOpenSettings(homeCubit, state)) return;
    _openSettingsAction!.call();
  }

  String _resolveDeviceTitle(Device device) {
    String take(String v) => v.trim();
    final alias = take(device.userData.alias);
    if (alias.isNotEmpty) return alias;
    final sn = take(device.sn);
    if (sn.isNotEmpty) return sn;
    return _defaultTitle;
  }

  Widget _buildSelectedDeviceOrFallback(HomeCubit homeCubit, String? deviceId) {
    final userDevices = homeCubit.getUserDevices();

    if (deviceId == null) {
      _setTitleSafe(null);
      _setSettingsActionSafe(null);
      return NoSelectedDevicePage(
        title: userDevices.isEmpty
            ? S.of(context).NoDevicesYet
            : S.of(context).NoDeviceSelected,
        subtitle: userDevices.isEmpty
            ? S.of(context).NoDeviceSelectedNoDevicesSubtitle
            : S.of(context).NoDeviceSelectedChooseDeviceSubtitle,
        actionLabel: userDevices.isEmpty
            ? S.of(context).AddDevice
            : S.of(context).OpenDevices,
        onActionPressed: userDevices.isEmpty
            ? () => Navigator.of(context).push(AddDevicePage.route())
            : () => _scaffoldKey.currentState?.openDrawer(),
      );
    }

    final device = homeCubit.getDeviceById(deviceId);
    if (device == null) {
      _setTitleSafe(null);
      _setSettingsActionSafe(null);
      return NoSelectedDevicePage(
        title: S.of(context).NoDeviceSelected,
        subtitle: S.of(context).NoDeviceSelectedChooseDeviceSubtitle,
        actionLabel: S.of(context).OpenDevices,
        onActionPressed: () => _scaffoldKey.currentState?.openDrawer(),
      );
    }

    _setTitleSafe(_resolveDeviceTitle(device));
    return DeviceScope(
      key: ValueKey(device.id),
      device: device,
      onTitleChanged: _setTitleSafe,
      onSettingsActionChanged: _setSettingsActionSafe,
    );
  }

  @override
  Widget build(BuildContext context) {
    return OshAnalyticsScreenView(
      screenName: OshAnalyticsScreens.home,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          centerTitle: true,
          title: Text(_title ?? _defaultTitle, overflow: TextOverflow.ellipsis),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: BlocSelector<HomeCubit, HomeState, String?>(
                selector: (state) => state.selectedDeviceId,
                builder: (context, deviceId) {
                  return MqttActivityIcon(key: ValueKey(deviceId));
                },
              ),
            ),
            BlocBuilder<HomeCubit, HomeState>(
              builder: (context, state) {
                final enabled =
                    _canOpenSettings(context.read<HomeCubit>(), state);
                return IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: S.of(context).Settings,
                  onPressed: enabled ? _onIconPressed : null,
                );
              },
            ),
          ],
        ),
        drawer: const SideMenu(),
        body: BlocBuilder<HomeCubit, HomeState>(
          buildWhen: (previous, current) {
            if (previous is HomeReady && current is HomeRefreshing) {
              return false;
            }
            if (previous is HomeRefreshing && current is HomeReady) {
              return false;
            }
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
                _setSettingsActionSafe(null);
                return const Loader();

              case HomeFailed(:final selectedDeviceId):
                return _buildSelectedDeviceOrFallback(
                  homeCubit,
                  selectedDeviceId,
                );

              case HomeReady(:final selectedDeviceId):
                return _buildSelectedDeviceOrFallback(
                  homeCubit,
                  selectedDeviceId,
                );
            }

            _setTitleSafe(null);
            _setSettingsActionSafe(null);
            return NoSelectedDevicePage(
              title: S.of(context).NoDeviceSelected,
              subtitle: S.of(context).NoDeviceSelectedChooseDeviceSubtitle,
              actionLabel: S.of(context).OpenDevices,
              onActionPressed: () => _scaffoldKey.currentState?.openDrawer(),
            );
          },
        ),
      ),
    );
  }
}
