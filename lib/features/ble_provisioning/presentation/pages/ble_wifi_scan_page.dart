import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/features/ble_provisioning/domain/entities/wifi_network.dart';
import 'package:oshmobile/features/ble_provisioning/presentation/cubit/ble_provisioning_cubit.dart';
import 'package:oshmobile/features/ble_provisioning/presentation/pages/ble_wifi_password_page.dart';
import 'package:oshmobile/features/ble_provisioning/presentation/widgets/wifi_list_step.dart';
import 'package:oshmobile/generated/l10n.dart';

class BleWifiScanPage extends StatefulWidget {
  final String deviceSn;
  final String secureCode;

  const BleWifiScanPage({
    super.key,
    required this.deviceSn,
    required this.secureCode,
  });

  @override
  State<BleWifiScanPage> createState() => _BleWifiScanPageState();
}

class _BleWifiScanPageState extends State<BleWifiScanPage> {
  bool _connectStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Ensure we call connect() only once when the page is attached.
    if (!_connectStarted) {
      _connectStarted = true;

      final cubit = context.read<BleProvisioningCubit>();

      // Start full BLE connect + Wi-Fi scan flow.
      cubit.connect(
        serialNumber: widget.deviceSn,
        secureCode: widget.secureCode,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return BlocConsumer<BleProvisioningCubit, BleProvisioningState>(
      listenWhen: (prev, cur) =>
          prev.status != cur.status ||
          prev.error != cur.error ||
          prev.lastConnectStatus != cur.lastConnectStatus,
      listener: (context, state) {
        final error = state.error;
        final s = S.of(context);

        if (error != null && error.isNotEmpty) {
          SnackBarUtils.showAlert(context: context, content: error);
          Navigator.of(context).pop(false);
          return;
        }

        final selected = state.selectedNetwork;
        if (selected?.auth == WifiAuthType.open) {
          if (state.status == ProvisioningStatus.wifiSuccess) {
            SnackBarUtils.showSuccess(
                context: context, content: s.deviceConnectedToWifi);
            Navigator.of(context).pop(true);
          } else if (state.status == ProvisioningStatus.wifiFailed) {
            final msg = state.lastConnectStatus?.message ?? s.wifiConnectFailed;
            SnackBarUtils.showAlert(context: context, content: msg);
          }
        }
      },
      builder: (context, state) {
        final status = state.status;

        Widget body;

        if (status == ProvisioningStatus.connectingBle) {
          body = _ConnectingBleView();
        } else {
          final isActive = status == ProvisioningStatus.wifiScanInProgress ||
              status == ProvisioningStatus.wifiConnecting;
          body = WifiListStep(
            isScanning: isActive,
            onNetworkSelected: (network) =>
                _onNetworkSelected(context, network),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(s.ChooseWiFi)),
          body: body,
        );
      },
    );
  }

  Future<void> _onNetworkSelected(BuildContext context, WifiNetwork network) async {
    final cubit = context.read<BleProvisioningCubit>();
    cubit.selectNetwork(network);

    if (network.auth == WifiAuthType.open) {
      cubit.connectWifi('');
      return;
    }

    final connected = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: const BleWifiPasswordPage(),
        ),
      ),
    );

    if (connected == true) {
      Navigator.of(context).pop(true);
    }
  }
}

/// Simple view shown while we are establishing BLE connection.
class _ConnectingBleView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(),
          ),
          const SizedBox(height: 16),
          Text(
            s.bleConnectingToDevice,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
