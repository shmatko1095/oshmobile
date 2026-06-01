import 'package:flutter/material.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/configuration/models/device_configuration_bundle.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/devices/details/domain/builders/thermostat_dashboard_schema_builder.dart';
import 'package:oshmobile/features/devices/details/domain/models/thermostat_dashboard_schema.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/adapters/thermostat_telemetry_history_opener.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/temperature_history_strip_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/temperature_minimal_panel.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/thermostat_mode_bar.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/delta_temp_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/heating_status_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/inlet_temp_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/load_factor_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/outlet_temp_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/power_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/power_metric_card.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';
import 'package:oshmobile/features/schedule/presentation/open_mode_editor.dart';
import 'package:oshmobile/features/sensors/presentation/open_sensor_editor.dart';
import 'package:oshmobile/features/telemetry_history/presentation/open_telemetry_history.dart';
import 'package:oshmobile/generated/l10n.dart';

import 'device_presenter.dart';

class ThermostatBasicPresenter implements DevicePresenter {
  const ThermostatBasicPresenter({
    required ThermostatDashboardSchemaBuilder schemaBuilder,
    required ThermostatTelemetryHistoryOpener historyOpener,
  })  : _schemaBuilder = schemaBuilder,
        _historyOpener = historyOpener;

  final ThermostatDashboardSchemaBuilder _schemaBuilder;
  final ThermostatTelemetryHistoryOpener _historyOpener;

  @override
  Widget build(
    BuildContext context,
    Device device,
    DeviceConfigurationBundle bundle,
  ) {
    const horizontalPadding = 20.0;
    const gridCrossAxisCount = 2;
    const gridCrossAxisSpacing = 16.0;
    const gridMainAxisSpacing = 16.0;
    const gridChildAspectRatio = 1.18;

    final contentWidth =
        MediaQuery.sizeOf(context).width - horizontalPadding * 2;
    final tileWidth =
        (contentWidth - gridCrossAxisSpacing * (gridCrossAxisCount - 1)) /
            gridCrossAxisCount;
    final statTileHeight = tileWidth / gridChildAspectRatio;

    final schema = _schemaBuilder.build(bundle: bundle);
    final scheduleWritable = bundle.canPatchDomain('schedule');

    final hero = schema.hero;
    final modeBar = schema.modeBar;
    final temperatureHistoryStrip = schema.temperatureHistoryStrip;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (hero != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
                  child: TemperatureMinimalPanel(
                    currentBind: hero.currentBind,
                    sensorsBind: hero.sensorsBind,
                    currentTargetBind: hero.currentTargetBind,
                    nextTargetBind: hero.nextTargetBind,
                    unit: '°C',
                    height: MediaQuery.sizeOf(context).height * 0.34,
                    onTap: scheduleWritable
                        ? () =>
                            ThermostatModeNavigator.openForCurrentMode(context)
                        : null,
                    onSensorActionTap: (sensor) {
                      SensorEditorNavigator.openFromHost(
                        context,
                        sensor: sensor,
                      );
                    },
                  ),
                ),
              ),
            if (modeBar != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: ThermostatModeBar(
                    modeBind: modeBar.modeBind,
                    visibleModes: _resolveVisibleModes(modeBar.visibleModeIds),
                    writable: scheduleWritable,
                  ),
                ),
              ),
            if (temperatureHistoryStrip != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    horizontalPadding,
                    12,
                    horizontalPadding,
                    0,
                  ),
                  child: TemperatureHistoryStripCard(
                    sensorsBind: temperatureHistoryStrip.sensorsBind,
                    height: statTileHeight,
                    onOpenHistory: (sensors, sensorId, sensorName) {
                      TelemetryHistoryNavigator.openTemperatureFromHost(
                        context,
                        sensors: sensors,
                        sensorId: sensorId,
                        sensorName: sensorName,
                      );
                    },
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                horizontalPadding,
                14,
                horizontalPadding,
                18,
              ),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridCrossAxisCount,
                  crossAxisSpacing: gridCrossAxisSpacing,
                  mainAxisSpacing: gridMainAxisSpacing,
                  childAspectRatio: gridChildAspectRatio,
                ),
                delegate: SliverChildListDelegate(
                  [for (final tile in schema.tiles) _buildTile(context, tile)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(BuildContext context, ThermostatTileSpec tile) {
    switch (tile) {
      case ThermostatSingleBindTileSpec(
          type: final type,
          bind: final bind,
          telemetryHistoryIntent: final historyIntent,
        ):
        return _buildSingleBindTile(
          context,
          type: type,
          bind: bind,
          historyIntent: historyIntent,
        );
      case ThermostatValueTileSpec(
          type: final type,
          valueBind: final valueBind,
          validBind: final validBind,
          telemetryHistoryIntent: final historyIntent,
        ):
        return _buildValueTile(
          context,
          type: type,
          valueBind: valueBind,
          validBind: validBind,
          historyIntent: historyIntent,
        );
      case ThermostatDeltaTileSpec(
          inletBind: final inletBind,
          outletBind: final outletBind,
        ):
        return DeltaTCard(
          inletBind: inletBind,
          outletBind: outletBind,
          unit: '°C',
        );
    }
  }

  Widget _buildSingleBindTile(
    BuildContext context, {
    required ThermostatTileType type,
    required String bind,
    required TelemetryHistoryIntent? historyIntent,
  }) {
    final s = S.of(context);

    switch (type) {
      case ThermostatTileType.heatingToggle:
        return HeatingStatusCard(
          bind: bind,
          title: s.Heating,
          onTap: () => TelemetryHistoryNavigator.openHeatingFromHost(context),
        );
      case ThermostatTileType.loadFactor24h:
        return LoadFactorKpiCard(
          percentBind: bind,
          title: s.TelemetryHistoryMetricLoadFactor,
          onTap: () =>
              TelemetryHistoryNavigator.openLoadFactorFromHost(context),
        );
      case ThermostatTileType.inletTemp:
        return InletTempCard(bind: bind);
      case ThermostatTileType.outletTemp:
        return OutletTempCard(bind: bind);
      case ThermostatTileType.powerNow:
      case ThermostatTileType.energyUsed:
      case ThermostatTileType.voltageNow:
      case ThermostatTileType.currentNow:
      case ThermostatTileType.apparentPowerNow:
      case ThermostatTileType.deltaT:
        return const SizedBox.shrink();
    }
  }

  Widget _buildValueTile(
    BuildContext context, {
    required ThermostatTileType type,
    required String valueBind,
    required String? validBind,
    required TelemetryHistoryIntent? historyIntent,
  }) {
    final s = S.of(context);

    switch (type) {
      case ThermostatTileType.energyUsed:
        return PowerMetricCard(
          valueBind: valueBind,
          validBind: validBind,
          title: s.TelemetryHistoryMetricEnergyUsed,
          unit: 'kWh',
          icon: Icons.bolt_rounded,
          accentColor: AppPalette.accentSuccess,
          decimals: 3,
          onTap: _historyTap(context, historyIntent),
        );
      case ThermostatTileType.powerNow:
        return PowerCard(
          bind: valueBind,
          validBind: validBind,
          title: s.TelemetryHistoryMetricActivePower,
          onTap: _historyTap(context, historyIntent),
        );
      case ThermostatTileType.voltageNow:
        return PowerMetricCard(
          valueBind: valueBind,
          validBind: validBind,
          title: s.TelemetryHistoryMetricVoltage,
          unit: 'V',
          icon: Icons.electrical_services_rounded,
          accentColor: AppPalette.amberAccent,
          onTap: _historyTap(context, historyIntent),
        );
      case ThermostatTileType.currentNow:
        return PowerMetricCard(
          valueBind: valueBind,
          validBind: validBind,
          title: s.TelemetryHistoryMetricCurrent,
          unit: 'A',
          icon: Icons.timeline_rounded,
          accentColor: AppPalette.cyanAccent,
          decimals: 2,
          onTap: _historyTap(context, historyIntent),
        );
      case ThermostatTileType.apparentPowerNow:
        return PowerMetricCard(
          valueBind: valueBind,
          validBind: validBind,
          title: s.TelemetryHistoryMetricApparentPower,
          unit: 'VA',
          icon: Icons.speed_rounded,
          accentColor: AppPalette.accentPrimary,
          onTap: _historyTap(context, historyIntent),
        );
      case ThermostatTileType.heatingToggle:
      case ThermostatTileType.loadFactor24h:
      case ThermostatTileType.inletTemp:
      case ThermostatTileType.outletTemp:
      case ThermostatTileType.deltaT:
        return const SizedBox.shrink();
    }
  }

  VoidCallback? _historyTap(
    BuildContext context,
    TelemetryHistoryIntent? historyIntent,
  ) {
    if (historyIntent == null) {
      return null;
    }
    return () => _historyOpener.open(context, intent: historyIntent);
  }

  List<CalendarMode>? _resolveVisibleModes(List<String>? modeIds) {
    if (modeIds == null || modeIds.isEmpty) {
      return null;
    }

    final byId = <String, CalendarMode>{
      for (final mode in CalendarMode.all) mode.id: mode,
    };

    final visibleModes = modeIds
        .map((id) => byId[id.trim()])
        .whereType<CalendarMode>()
        .toList(growable: false);
    return visibleModes.isEmpty ? null : visibleModes;
  }
}
