import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/app/device_session/scopes/device_route_scope.dart';
import 'package:oshmobile/core/analytics/osh_analytics_screens.dart';
import 'package:oshmobile/core/common/widgets/app_card.dart';
import 'package:oshmobile/core/network/mqtt/protocol/v1/sensors_models.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/sensors/presentation/pages/sensor_pairing_result_page.dart';
import 'package:oshmobile/generated/l10n.dart';

class SensorPairingSearchPage extends StatefulWidget {
  const SensorPairingSearchPage({
    super.key,
    required this.transport,
    required this.timeoutSec,
  });

  final String transport;
  final int timeoutSec;

  @override
  State<SensorPairingSearchPage> createState() =>
      _SensorPairingSearchPageState();
}

class _SensorPairingSearchPageState extends State<SensorPairingSearchPage> {
  final Set<String> _baselineZigbeeIds = <String>{};
  StreamSubscription<SensorsState>? _sensorsSub;
  Timer? _timeoutTimer;
  DeviceFacade? _facade;
  DeviceSnapshotCubit? _snapshotCubit;
  bool _completed = false;
  bool _pairingStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_start());
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    final sensorsSub = _sensorsSub;
    if (sensorsSub != null) unawaited(sensorsSub.cancel());
    if (!_completed && _pairingStarted) {
      unawaited(_setPairing(false));
    }
    super.dispose();
  }

  Future<void> _start() async {
    final facade = context.read<DeviceFacade>();
    _facade = facade;
    _snapshotCubit = context.read<DeviceSnapshotCubit>();
    SensorsState? initial = facade.sensors.current;
    try {
      initial ??= await facade.sensors.get();
    } catch (_) {
      if (mounted) _finish(SensorPairingResultMode.unavailable);
      return;
    }

    _baselineZigbeeIds
      ..clear()
      ..addAll(_zigbeeIds(initial));

    _sensorsSub = facade.sensors.watch().listen(
      _handleSensorsState,
      onError: (_) {
        if (mounted) _finish(SensorPairingResultMode.unavailable);
      },
      cancelOnError: false,
    );

    try {
      await facade.sensors.setPairing(
        enabled: true,
        timeoutSec: widget.timeoutSec,
      );
      _pairingStarted = true;
      if (_completed) {
        unawaited(_setPairing(false));
        return;
      }
    } catch (_) {
      if (mounted) _finish(SensorPairingResultMode.unavailable);
      return;
    }

    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(
      Duration(seconds: widget.timeoutSec),
      () {
        if (mounted) _finish(SensorPairingResultMode.notFound);
      },
    );
  }

  void _handleSensorsState(SensorsState state) {
    if (_completed) return;

    for (final sensor in state.items) {
      if (!_isZigbee(sensor) || _baselineZigbeeIds.contains(sensor.id)) {
        continue;
      }
      _finish(
        SensorPairingResultMode.found,
        sensorName: _displayName(sensor),
      );
      return;
    }

    if (_pairingStarted &&
        _isPairingTransport(state.pairing) &&
        !state.pairing.enabled) {
      _finish(SensorPairingResultMode.notFound);
    }
  }

  Set<String> _zigbeeIds(SensorsState state) {
    return state.items.where(_isZigbee).map((sensor) => sensor.id).toSet();
  }

  bool _isZigbee(SensorMeta sensor) {
    return sensor.transport.trim().toLowerCase() == 'zigbee';
  }

  bool _isPairingTransport(SensorPairing pairing) {
    return pairing.transport.trim().toLowerCase() ==
        widget.transport.trim().toLowerCase();
  }

  String _displayName(SensorMeta sensor) {
    final name = sensor.name.trim();
    return name.isEmpty ? sensor.id : name;
  }

  Future<void> _setPairing(bool enabled) {
    final facade = _facade;
    if (facade == null) return Future<void>.value();
    return facade.sensors.setPairing(
      enabled: enabled,
      timeoutSec: enabled ? widget.timeoutSec : null,
    );
  }

  void _finish(
    SensorPairingResultMode mode, {
    String? sensorName,
  }) {
    if (_completed) return;
    _completed = true;
    _timeoutTimer?.cancel();
    final sensorsSub = _sensorsSub;
    if (sensorsSub != null) unawaited(sensorsSub.cancel());
    if (_pairingStarted) {
      unawaited(_setPairing(false));
    }
    if (!mounted) return;

    final facade = _facade ?? context.read<DeviceFacade>();
    final snapshotCubit = _snapshotCubit ?? context.read<DeviceSnapshotCubit>();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        settings:
            const RouteSettings(name: OshAnalyticsScreens.sensorPairingResult),
        builder: (_) => DeviceRouteScope.provide(
          facade: facade,
          snapshotCubit: snapshotCubit,
          child: SensorPairingResultPage(
            mode: mode,
            transport: widget.transport,
            timeoutSec: widget.timeoutSec,
            sensorName: sensorName,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(s.AddSensor),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AppSolidCard(
              radius: AppPalette.radiusXl,
              borderColor: AppPalette.accentPrimary.withValues(
                alpha: isDark ? 0.24 : 0.18,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 42,
                    height: 42,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    s.SensorPairingSearching,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
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
