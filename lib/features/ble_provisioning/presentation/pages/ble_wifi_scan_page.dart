import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/features/ble_provisioning/domain/entities/wifi_network.dart';
import 'package:oshmobile/features/ble_provisioning/presentation/cubit/ble_provisioning_cubit.dart';
import 'package:oshmobile/features/ble_provisioning/presentation/pages/ble_wifi_password_page.dart';
import 'package:oshmobile/features/ble_provisioning/presentation/widgets/wifi_list_step.dart';
import 'package:oshmobile/generated/l10n.dart';

class BleWifiScanPage extends StatelessWidget {
  const BleWifiScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BleProvisioningCubit, BleProvisioningState>(
      listenWhen: (prev, cur) => prev.status != cur.status || prev.error != cur.error,
      listener: (context, state) async {
        if (state.status == ProvisioningStatus.error && state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state.status == ProvisioningStatus.initial ||
            state.status == ProvisioningStatus.connectingBle ||
            state.status == ProvisioningStatus.wifiConnecting;

        return Scaffold(
          appBar: AppBar(
            title: Text(S.of(context).ChooseWiFi),
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : WifiListStep(
                  isScanning: state.status == ProvisioningStatus.wifiScanInProgress,
                  onNetworkSelected: (network) => _onNetworkSelected(context, network),
                ),
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
