import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/common/widgets/app_button.dart';
import 'package:oshmobile/features/ble_provisioning/presentation/cubit/ble_provisioning_cubit.dart';
import 'package:oshmobile/features/ble_provisioning/presentation/pages/ble_wifi_scan_page.dart';
import 'package:oshmobile/generated/l10n.dart';

final _sl = GetIt.instance;

class DeviceOfflinePage extends StatelessWidget {
  final Device device;

  const DeviceOfflinePage({
    super.key,
    required this.device,
  });

  @override
  Widget build(BuildContext context) {
    final lastOnline = device.connectionInfo.timestampText;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          size: 120,
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Device Is Offline',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No internet connection detected.\n'
                          'Connect to a Wi-Fi network to continue.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppButton(
                        onPressed: () => _openBleProvisioning(context),
                        text: S.of(context).ChooseWiFi,
                      ),
                      if (lastOnline.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Last online: $lastOnline',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openBleProvisioning(BuildContext context) {
    const secureCodeStub = 'TODO_SECURE_CODE';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => _sl<BleProvisioningCubit>()
            ..start(
              serialNumber: device.sn,
              secureCode: secureCodeStub,
            ),
          child: const BleWifiScanPage(),
        ),
      ),
    );
  }
}
