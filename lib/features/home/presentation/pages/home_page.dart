import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:oshmobile/app/device_session/scopes/device_scope.dart';
import 'package:oshmobile/core/analytics/osh_analytics_screen_view.dart';
import 'package:oshmobile/core/analytics/osh_analytics_screens.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/common/widgets/loader.dart';
import 'package:oshmobile/features/device_catalog/presentation/cubit/device_catalog_cubit.dart';
import 'package:oshmobile/features/device_management/presentation/pages/device_settings_hub_page.dart';
import 'package:oshmobile/features/devices/no_selected_device/presentation/pages/no_selected_device_page.dart';
import 'package:oshmobile/features/home/presentation/pages/add_device_page.dart';
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
  String? _sessionTitle;
  String? _sessionTitleDeviceId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeviceCatalogCubit>().refresh();
    });
  }

  void _setSessionTitle(String deviceId, String? title) {
    if (!mounted) return;
    final next = title?.trim();
    final normalized = (next == null || next.isEmpty) ? null : next;
    if (_sessionTitle == normalized && _sessionTitleDeviceId == deviceId) {
      return;
    }
    setState(() {
      _sessionTitle = normalized;
      _sessionTitleDeviceId = deviceId;
    });
  }

  Device? _selectedDevice(
    DeviceCatalogCubit deviceCatalogCubit,
    DeviceCatalogState state,
  ) {
    final selectedId = state.selectedDeviceId;
    if (selectedId == null) return null;
    return deviceCatalogCubit.getById(selectedId);
  }

  String _resolveDeviceTitle(Device device) {
    String take(String value) => value.trim();
    final alias = take(device.userData.alias);
    if (alias.isNotEmpty) return alias;
    final sn = take(device.sn);
    if (sn.isNotEmpty) return sn;
    final modelName = take(device.modelName);
    if (modelName.isNotEmpty) return modelName;
    return _defaultTitle;
  }

  String _resolveAppBarTitle(
    DeviceCatalogCubit deviceCatalogCubit,
    DeviceCatalogState state,
  ) {
    final selectedDevice = _selectedDevice(deviceCatalogCubit, state);
    if (selectedDevice == null) {
      return _defaultTitle;
    }

    if (_sessionTitleDeviceId == selectedDevice.id &&
        _sessionTitle != null &&
        _sessionTitle!.isNotEmpty) {
      return _sessionTitle!;
    }

    return _resolveDeviceTitle(selectedDevice);
  }

  void _openSettings() {
    final deviceCatalogCubit = context.read<DeviceCatalogCubit>();
    final device =
        _selectedDevice(deviceCatalogCubit, deviceCatalogCubit.state);
    if (device == null) return;

    Navigator.of(context).push(
      DeviceSettingsHubPage.route(deviceId: device.id),
    );
  }

  Widget _buildSelectedDeviceOrFallback(
    DeviceCatalogCubit deviceCatalogCubit,
    DeviceCatalogState state,
  ) {
    final userDevices = deviceCatalogCubit.getAll();
    final selectedId = state.selectedDeviceId;

    if (selectedId == null) {
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

    final device = deviceCatalogCubit.getById(selectedId);
    if (device == null) {
      return NoSelectedDevicePage(
        title: S.of(context).NoDeviceSelected,
        subtitle: S.of(context).NoDeviceSelectedChooseDeviceSubtitle,
        actionLabel: S.of(context).OpenDevices,
        onActionPressed: () => _scaffoldKey.currentState?.openDrawer(),
      );
    }

    return DeviceScope(
      key: ValueKey(device.id),
      device: device,
      onTitleChanged: (title) => _setSessionTitle(device.id, title),
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
          title: BlocBuilder<DeviceCatalogCubit, DeviceCatalogState>(
            builder: (context, state) {
              final title = _resolveAppBarTitle(
                  context.read<DeviceCatalogCubit>(), state);
              return Text(title, overflow: TextOverflow.ellipsis);
            },
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child:
                  BlocSelector<DeviceCatalogCubit, DeviceCatalogState, String?>(
                selector: (state) => state.selectedDeviceId,
                builder: (context, deviceId) {
                  return MqttActivityIcon(key: ValueKey(deviceId));
                },
              ),
            ),
            BlocBuilder<DeviceCatalogCubit, DeviceCatalogState>(
              builder: (context, state) {
                final enabled = _selectedDevice(
                        context.read<DeviceCatalogCubit>(), state) !=
                    null;
                return IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: S.of(context).Settings,
                  onPressed: enabled ? _openSettings : null,
                );
              },
            ),
          ],
        ),
        drawer: const SideMenu(),
        body: BlocBuilder<DeviceCatalogCubit, DeviceCatalogState>(
          builder: (context, state) {
            final deviceCatalogCubit = context.read<DeviceCatalogCubit>();

            if (state.status == DeviceCatalogStatus.initial ||
                (state.status == DeviceCatalogStatus.loading &&
                    state.devices.isEmpty)) {
              return const Loader();
            }

            return _buildSelectedDeviceOrFallback(deviceCatalogCubit, state);
          },
        ),
      ),
    );
  }
}
