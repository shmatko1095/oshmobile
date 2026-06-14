import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/app/device_session/scopes/device_route_scope.dart';
import 'package:oshmobile/core/analytics/osh_analytics_screens.dart';
import 'package:oshmobile/core/common/widgets/app_button.dart';
import 'package:oshmobile/core/common/widgets/app_card.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/sensors/presentation/pages/sensor_pairing_search_page.dart';
import 'package:oshmobile/generated/l10n.dart';

enum SensorPairingResultMode {
  found,
  notFound,
  unavailable,
}

class SensorPairingResultPage extends StatelessWidget {
  const SensorPairingResultPage({
    super.key,
    required this.mode,
    required this.transport,
    required this.timeoutSec,
    this.sensorName,
  });

  final SensorPairingResultMode mode;
  final String transport;
  final int timeoutSec;
  final String? sensorName;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final title = switch (mode) {
      SensorPairingResultMode.found => s.SensorPairingFoundTitle,
      SensorPairingResultMode.notFound => s.SensorPairingNotFoundTitle,
      SensorPairingResultMode.unavailable => s.SensorPairingUnavailableTitle,
    };
    final message = switch (mode) {
      SensorPairingResultMode.found =>
        s.SensorPairingFoundMessage(_displayName),
      SensorPairingResultMode.notFound => s.SensorPairingNotFoundMessage,
      SensorPairingResultMode.unavailable => s.SensorPairingUnavailableMessage,
    };
    final icon = switch (mode) {
      SensorPairingResultMode.found => Icons.check_rounded,
      SensorPairingResultMode.notFound => Icons.search_off_rounded,
      SensorPairingResultMode.unavailable => Icons.warning_amber_rounded,
    };

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(title),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: AppSolidCard(
                    radius: AppPalette.radiusXl,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 52,
                          color: AppPalette.accentPrimary,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AppButton(
                text: mode == SensorPairingResultMode.found ? s.OK : s.Retry,
                onPressed: mode == SensorPairingResultMode.found
                    ? () => Navigator.of(context).pop()
                    : () => _retry(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _displayName {
    final value = sensorName?.trim();
    if (value != null && value.isNotEmpty) return value;
    return 'Zigbee sensor';
  }

  void _retry(BuildContext context) {
    final facade = context.read<DeviceFacade>();
    final snapshotCubit = context.read<DeviceSnapshotCubit>();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        settings: const RouteSettings(name: OshAnalyticsScreens.sensorPairing),
        builder: (_) => DeviceRouteScope.provide(
          facade: facade,
          snapshotCubit: snapshotCubit,
          child: SensorPairingSearchPage(
            transport: transport,
            timeoutSec: timeoutSec,
          ),
        ),
      ),
    );
  }
}
