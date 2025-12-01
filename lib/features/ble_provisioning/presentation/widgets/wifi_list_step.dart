import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/widgets/app_button.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/ble_provisioning/domain/entities/wifi_network.dart';
import 'package:oshmobile/features/ble_provisioning/presentation/cubit/ble_provisioning_cubit.dart';
import 'package:oshmobile/generated/l10n.dart';

class WifiListStep extends StatelessWidget {
  final bool isScanning;
  final void Function(WifiNetwork) onNetworkSelected;

  const WifiListStep({
    super.key,
    required this.isScanning,
    required this.onNetworkSelected,
  });

  @override
  Widget build(BuildContext context) {
    final networks = context.select((BleProvisioningCubit cubit) => cubit.state.networks);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            S.of(context).ChooseWifiToConnect,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: networks.isEmpty
                ? Center(
                    child: isScanning
                        ? const SizedBox()
                        : Text(
                            S.of(context).NoNetworksFound,
                            style: const TextStyle(color: Colors.grey),
                          ),
                  )
                : ListView.separated(
                    itemCount: networks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final n = networks[index];
                      return _WifiTile(
                        network: n,
                        onTap: () => onNetworkSelected(n),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          AppButton(
            isLoading: isScanning,
            onPressed: () => context.read<BleProvisioningCubit>().refreshScan(),
            text: S.of(context).Search,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _WifiTile extends StatelessWidget {
  final WifiNetwork network;
  final VoidCallback onTap;

  const _WifiTile({
    required this.network,
    required this.onTap,
  });

  /// Helper method to choose the correct icon based on signal strength (RSSI)
  IconData _getSignalIcon(int rssi) {
    if (rssi >= -55) {
      return Icons.network_wifi;
    } else if (rssi >= -70) {
      return Icons.network_wifi_3_bar;
    } else if (rssi >= -85) {
      return Icons.network_wifi_2_bar;
    } else {
      return Icons.network_wifi_1_bar;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tileColor = isDark ? AppPalette.cardDark : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final iconColor = isDark ? Colors.white70 : Colors.black54;

    return Material(
      color: tileColor,
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDark ? BorderSide(color: Colors.white10) : BorderSide.none,
      ),
      child: ListTile(
        title: Text(
          network.ssid,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (network.auth != WifiAuthType.open)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.lock_outline, size: 18, color: iconColor),
              ),
            Icon(_getSignalIcon(network.rssi), size: 22, color: iconColor),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
