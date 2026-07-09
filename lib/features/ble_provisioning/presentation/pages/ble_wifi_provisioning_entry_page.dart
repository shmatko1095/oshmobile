import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/analytics/osh_analytics_screen_view.dart';
import 'package:oshmobile/core/analytics/osh_analytics_screens.dart';
import 'package:oshmobile/core/common/widgets/app_button.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/ble_provisioning/presentation/ble_provisioning_flow.dart';
import 'package:oshmobile/features/ble_provisioning/presentation/cubit/ble_provisioning_cubit.dart';
import 'package:oshmobile/generated/l10n.dart';
import 'package:oshmobile/init_dependencies.dart';

class BleWifiProvisioningEntryPage extends StatelessWidget {
  const BleWifiProvisioningEntryPage({
    super.key,
    required this.deviceSn,
    required this.createCubit,
    this.secureCode = bleProvisioningSecureCodeStub,
  });

  final String deviceSn;
  final String secureCode;
  final BleProvisioningCubitFactory createCubit;

  static MaterialPageRoute<bool> route({
    required String deviceSn,
    String secureCode = bleProvisioningSecureCodeStub,
    BleProvisioningCubitFactory? createCubit,
  }) {
    return MaterialPageRoute<bool>(
      settings: const RouteSettings(
        name: OshAnalyticsScreens.bleWifiProvisioningEntry,
      ),
      builder: (_) => BleWifiProvisioningEntryPage(
        deviceSn: deviceSn,
        secureCode: secureCode,
        createCubit: createCubit ?? () => locator<BleProvisioningCubit>(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BleProvisioningCubit>(
      create: (_) => createCubit(),
      child: _BleWifiProvisioningEntryView(
        deviceSn: deviceSn,
        secureCode: secureCode,
      ),
    );
  }
}

class _BleWifiProvisioningEntryView extends StatelessWidget {
  const _BleWifiProvisioningEntryView({
    required this.deviceSn,
    required this.secureCode,
  });

  final String deviceSn;
  final String secureCode;

  Future<void> _startWifiSearch(BuildContext context) async {
    final connected = await openBleWifiProvisioningFlow(
      context: context,
      cubit: context.read<BleProvisioningCubit>(),
      deviceSn: deviceSn,
      secureCode: secureCode,
    );

    if (!context.mounted) return;
    if (connected == true) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? AppPalette.textPrimary : AppPalette.lightTextPrimary;
    final secondaryTextColor =
        isDark ? AppPalette.textSecondary : AppPalette.lightTextSecondary;

    return OshAnalyticsScreenView(
      screenName: OshAnalyticsScreens.bleWifiProvisioningEntry,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            s.AddWifiNetworkAction,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            children: [
              Icon(
                Icons.wifi_tethering_rounded,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppPalette.spaceXl),
              Text(
                s.AddWifiNetworkAction,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppPalette.spaceMd),
              Text(
                s.BleWifiProvisioningHint,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: secondaryTextColor,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppPalette.space2xl),
              AppButton(
                text: s.StartWifiSearch,
                icon: const Icon(Icons.search_rounded),
                onPressed: () => _startWifiSearch(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
