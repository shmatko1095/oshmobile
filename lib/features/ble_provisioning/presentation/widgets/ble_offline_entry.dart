import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:oshmobile/core/common/widgets/app_button.dart';
import 'package:oshmobile/features/ble_provisioning/presentation/cubit/ble_provisioning_cubit.dart';
import 'package:oshmobile/features/ble_provisioning/presentation/pages/ble_wifi_scan_page.dart';
import 'package:oshmobile/generated/l10n.dart';

final _sl = GetIt.instance;

class BleOfflineEntry extends StatelessWidget {
  final String deviceSn;
  final String secureCode;
  final String? lastOnlineText;
  final VoidCallback? onWifiProvisioningSuccess;

  const BleOfflineEntry({
    super.key,
    required this.deviceSn,
    required this.secureCode,
    required this.onWifiProvisioningSuccess,
    this.lastOnlineText,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey('ble_offline_$deviceSn'),
      create: (_) => _sl<BleProvisioningCubit>()
        ..startNearbyCheck(
          serialNumber: deviceSn,
        ),
      child: _BleOfflineEntryBody(
        deviceSn: deviceSn,
        secureCode: secureCode,
        onWifiProvisioningSuccess: onWifiProvisioningSuccess,
      ),
    );
  }
}

class _BleOfflineEntryBody extends StatelessWidget {
  final String deviceSn;
  final String secureCode;
  final VoidCallback? onWifiProvisioningSuccess;

  const _BleOfflineEntryBody({
    required this.deviceSn,
    required this.secureCode,
    required this.onWifiProvisioningSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<BleProvisioningCubit, BleProvisioningState>(
      builder: (context, state) {
        final s = S.of(context);

        final isAvailable = state.deviceNearby == true;
        final needPermission = state.status == ProvisioningStatus.permissionDenied;

        Widget child;
        String? helperText;

        if (needPermission) {
          child = const SizedBox.shrink();
          helperText = s.offlineBlePermissionHint;
        } else if (isAvailable) {
          child = AppButton(
            text: s.ChooseWiFi,
            onPressed: () => _openBleFlow(context),
          );
        } else {
          child = const SizedBox.shrink();
          helperText = s.offlineBleNotNearbyHint;
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            child,
            if (helperText != null) ...[
              if (child is! SizedBox) const SizedBox(height: 12),
              Text(
                helperText,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _openBleFlow(BuildContext context) async {
    final cubit = context.read<BleProvisioningCubit>();

    await cubit.ensureBleDisconnected();
    cubit.resetForNewFlow();

    final connected = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: BleWifiScanPage(
            deviceSn: deviceSn,
            secureCode: secureCode,
          ),
        ),
      ),
    );

    if (!context.mounted) return;

    cubit.startNearbyCheck(serialNumber: deviceSn);

    if (connected == true) {
      onWifiProvisioningSuccess?.call();
    }
  }
}
