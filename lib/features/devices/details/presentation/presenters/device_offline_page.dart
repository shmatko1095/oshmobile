import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/common/widgets/app_card.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
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
    final textTheme = Theme.of(context).textTheme;
    final s = S.of(context);
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final lastSeenAt = device.connectionInfo.timestamp;
    final lastSeenLabel = lastSeenAt == null
        ? null
        : DateFormat.yMMMd(localeTag).add_Hm().format(lastSeenAt.toLocal());
    final subtitle = lastSeenLabel == null
        ? null
        : s.deviceOfflineSubtitleWithLastSeen(lastSeenLabel);

    const secureCodeStub = 'TODO_SECURE_CODE';

    return Scaffold(
      backgroundColor: AppPalette.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppPalette.spaceXl,
                vertical: AppPalette.spaceLg,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 124,
                    height: 124,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppPalette.accentPrimary.withValues(alpha: 0.30),
                          AppPalette.canvas,
                        ],
                        radius: 0.85,
                      ),
                    ),
                    child: const Icon(
                      Icons.wifi_off_rounded,
                      size: 58,
                      color: AppPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppPalette.spaceXl),
                  AppSolidCard(
                    backgroundColor: AppPalette.surface,
                    borderColor: AppPalette.borderSoft,
                    padding: const EdgeInsets.all(AppPalette.spaceXl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          s.deviceOfflineTitle,
                          textAlign: TextAlign.center,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppPalette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppPalette.spaceSm),
                        if (subtitle != null) ...[
                          const SizedBox(height: AppPalette.spaceSm),
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppPalette.textSecondary,
                              height: 1.45,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppPalette.spaceLg),
                        _HintRow(
                          icon: Icons.wifi,
                          text: s.TipCheckNetwork,
                        ),
                        const SizedBox(height: AppPalette.spaceSm),
                        _HintRow(
                          icon: Icons.bluetooth_searching_rounded,
                          text: s.deviceOfflineHintBluetooth,
                        ),
                        const SizedBox(height: AppPalette.spaceXl),
                        BleOfflineEntry(
                          deviceSn: device.sn,
                          secureCode: secureCodeStub,
                          lastOnlineText: device.connectionInfo.timestampText,
                          onWifiProvisioningSuccess: onWifiProvisioningSuccess,
                        ),
                      ],
                    ),
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

class _HintRow extends StatelessWidget {
  const _HintRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppPalette.accentPrimary),
        const SizedBox(width: AppPalette.spaceSm),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppPalette.textSecondary,
                  height: 1.35,
                ),
          ),
        ),
      ],
    );
  }
}
