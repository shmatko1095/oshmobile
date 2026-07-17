import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/device_presenter_chrome.dart';
import 'package:oshmobile/generated/l10n.dart';

class ThermostatDashboardAppBar extends StatelessWidget {
  const ThermostatDashboardAppBar({
    super.key,
    required this.roomName,
    required this.chrome,
  });

  final String roomName;
  final DevicePresenterChrome? chrome;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      key: const ValueKey('thermostat-dashboard-app-bar'),
      pinned: true,
      primary: true,
      automaticallyImplyLeading: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: AppPalette.transparent,
      leading: chrome == null
          ? null
          : IconButton(
              key: const ValueKey('thermostat-open-drawer'),
              onPressed: chrome!.onOpenDrawer,
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              icon: const Icon(Icons.menu_rounded),
            ),
      title: Text(
        roomName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: chrome == null
          ? null
          : [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: chrome!.activityIndicator,
              ),
              IconButton(
                key: const ValueKey('thermostat-open-settings'),
                onPressed: chrome!.onOpenSettings,
                tooltip: S.of(context).Settings,
                icon: const Icon(Icons.settings),
              ),
            ],
    );
  }
}
