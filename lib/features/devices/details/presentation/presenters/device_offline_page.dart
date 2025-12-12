import 'package:flutter/material.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/features/ble_provisioning/presentation/widgets/ble_offline_entry.dart';
import 'package:oshmobile/generated/l10n.dart';

class DeviceOfflinePage extends StatelessWidget {
  final Device device;
  final VoidCallback? onWifiProvisioningSuccess;

  const DeviceOfflinePage({
    super.key,
    required this.device,
    required this.onWifiProvisioningSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final lastOnline = device.connectionInfo.timestampText;
    final theme = Theme.of(context);
    final s = S.of(context);

    const secureCodeStub = 'TODO_SECURE_CODE';

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
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          s.deviceOfflineTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.deviceOfflineSubtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                          ),
                        ),
                        if (lastOnline.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Last online: $lastOnline',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  BleOfflineEntry(
                    deviceSn: device.sn,
                    secureCode: secureCodeStub,
                    lastOnlineText: lastOnline,
                    onWifiProvisioningSuccess: onWifiProvisioningSuccess,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
