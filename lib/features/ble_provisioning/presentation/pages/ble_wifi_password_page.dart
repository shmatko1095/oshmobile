import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/features/ble_provisioning/presentation/cubit/ble_provisioning_cubit.dart';
import 'package:oshmobile/features/ble_provisioning/presentation/widgets/wifi_password_step.dart';

class BleWifiPasswordPage extends StatelessWidget {
  const BleWifiPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BleProvisioningCubit, BleProvisioningState>(
      listenWhen: (prev, cur) =>
          prev.status != cur.status || prev.lastConnectStatus != cur.lastConnectStatus || prev.error != cur.error,
      listener: (context, state) {
        if (state.status == ProvisioningStatus.wifiSuccess) {
          SnackBarUtils.showSuccess(context: context, content: "Device connected to Wi-Fi");
          Navigator.of(context).pop(true);
        } else if (state.status == ProvisioningStatus.wifiFailed) {
          SnackBarUtils.showFail(context: context, content: "Failed to connect");
        } else if (state.status == ProvisioningStatus.error && state.error != null) {
          SnackBarUtils.showFail(context: context, content: state.error!);
        }
      },
      builder: (context, state) {
        final network = state.selectedNetwork;
        final title = network?.ssid ?? 'Wi-Fi';
        final isConnecting = state.status == ProvisioningStatus.wifiConnecting;

        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: WifiPasswordStep(isConnecting: isConnecting),
        );
      },
    );
  }
}
