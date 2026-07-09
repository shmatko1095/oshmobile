import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/analytics/osh_analytics_screens.dart';
import 'package:oshmobile/features/ble_provisioning/presentation/cubit/ble_provisioning_cubit.dart';
import 'package:oshmobile/features/ble_provisioning/presentation/pages/ble_wifi_scan_page.dart';

typedef BleProvisioningCubitFactory = BleProvisioningCubit Function();

const bleProvisioningSecureCodeStub = 'TODO_SECURE_CODE';

Future<bool?> openBleWifiProvisioningFlow({
  required BuildContext context,
  required BleProvisioningCubit cubit,
  required String deviceSn,
  required String secureCode,
}) async {
  final navigator = Navigator.of(context);

  await cubit.ensureBleDisconnected();
  if (!context.mounted) return false;
  cubit.resetForNewFlow();

  return navigator.push<bool>(
    MaterialPageRoute<bool>(
      settings: const RouteSettings(name: OshAnalyticsScreens.bleWifiScan),
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: BleWifiScanPage(
          deviceSn: deviceSn,
          secureCode: secureCode,
        ),
      ),
    ),
  );
}
