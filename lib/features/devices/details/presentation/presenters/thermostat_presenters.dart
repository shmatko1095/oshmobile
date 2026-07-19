import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/app/device_session/domain/device_snapshot.dart';
import 'package:oshmobile/app/device_session/domain/models/device_temperature_sensor_ref.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/configuration/models/device_configuration_bundle.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/devices/details/domain/builders/thermostat_dashboard_schema_builder.dart';
import 'package:oshmobile/features/devices/details/domain/models/thermostat_dashboard_schema.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/adapters/thermostat_telemetry_history_opener.dart';
import 'package:oshmobile/features/devices/details/presentation/user_guide/thermostat_live_metrics_guide_gate.dart';
import 'package:oshmobile/features/devices/details/presentation/user_guide/thermostat_user_guide_target_host.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/utils/thermostat_dashboard_layout.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/utils/temperature_sensors_resolver.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/temperature_minimal_panel.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/temperature_history_strip_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/heating_status_horizontal_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/thermostat_dashboard_app_bar.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/thermostat_live_metrics_overlay.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/thermostat_live_metrics_sheet.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/thermostat_mode_bar.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/delta_temp_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/daily_energy_usage_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/daily_heating_usage_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/heating_status_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/inlet_temp_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/outlet_temp_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/power_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/power_metric_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/glass_stat_card.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';
import 'package:oshmobile/features/schedule/presentation/open_mode_editor.dart';
import 'package:oshmobile/features/sensors/presentation/open_sensor_editor.dart';
import 'package:oshmobile/features/sensors/presentation/open_sensor_pairing.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/temperature_history_preview_cache.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/daily_energy_usage_cache.dart';
import 'package:oshmobile/features/user_guide/presentation/coordination/user_guide_host_registry.dart';
import 'package:oshmobile/features/user_guide/presentation/cubit/user_guide_cubit.dart';
import 'package:oshmobile/generated/l10n.dart';

import 'device_presenter.dart';
import 'device_presenter_chrome.dart';

class ThermostatBasicPresenter implements DevicePresenter {
  const ThermostatBasicPresenter({
    required ThermostatDashboardSchemaBuilder schemaBuilder,
    required ThermostatTelemetryHistoryOpener historyOpener,
    required TemperatureHistoryPreviewCache historyPreviewCache,
    required DailyEnergyUsageCache dailyEnergyCache,
  })  : _schemaBuilder = schemaBuilder,
        _historyOpener = historyOpener,
        _historyPreviewCache = historyPreviewCache,
        _dailyEnergyCache = dailyEnergyCache;

  final ThermostatDashboardSchemaBuilder _schemaBuilder;
  final ThermostatTelemetryHistoryOpener _historyOpener;
  final TemperatureHistoryPreviewCache _historyPreviewCache;
  final DailyEnergyUsageCache _dailyEnergyCache;

  @override
  bool get usesEmbeddedAppBar => true;

  @override
  Widget build(
    BuildContext context,
    Device device,
    DeviceConfigurationBundle bundle, {
    DevicePresenterChrome? chrome,
  }) {
    final schema = _schemaBuilder.build(bundle: bundle);
    final scheduleWritable = bundle.canPatchDomain('schedule');

    final hero = schema.hero;
    final modeBar = schema.modeBar;
    final heatingStatus = schema.heatingStatus;
    final temperatureHistoryStrip = schema.temperatureHistoryStrip;
    final climateSensorPairing = schema.climateSensorPairing;
    final roomName = _resolveDeviceTitle(device);
    final hasLiveMetrics = schema.tiles.isNotEmpty;
    final userGuideCubit = context.read<UserGuideCubit>();
    final userGuideHostRegistry = context.read<UserGuideHostRegistry>();
    final visibleModes =
        modeBar == null ? null : _resolveVisibleModes(modeBar.visibleModeIds);

    return BlocBuilder<DeviceSnapshotCubit, DeviceSnapshot>(
      buildWhen: (previous, current) =>
          _historySensorSignature(previous, hero) !=
          _historySensorSignature(current, hero),
      builder: (context, snapshot) {
        final historySensors = _historySensors(snapshot, hero);
        final configuredHistoryAction = _historyOpener.prepareDashboard(
          context,
          title: roomName,
          history: bundle.configuration.history,
          sensors: historySensors,
          initialSensorId: _referenceSensorId(historySensors),
        );
        final historyAvailable = configuredHistoryAction != null;

        return ThermostatUserGuideTargetHost(
          registry: userGuideHostRegistry,
          cubit: userGuideCubit,
          enabled: hasLiveMetrics,
          builder: (context, temperatureTargetKey, modeBarTargetKey) =>
              Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final viewportHeight = constraints.maxHeight.isFinite
                    ? constraints.maxHeight
                    : MediaQuery.sizeOf(context).height;
                final topInset = MediaQuery.paddingOf(context).top;
                final bottomInset = MediaQuery.paddingOf(context).bottom;
                final textScale =
                    (MediaQuery.textScalerOf(context).scale(12) / 12)
                        .clamp(1.0, 2.0);
                final landscape = constraints.maxWidth > constraints.maxHeight;
                final dashboardLayout = resolveThermostatDashboardLayout(
                  viewportHeight: viewportHeight,
                  topInset: topInset,
                  bottomInset: bottomInset,
                  textScale: textScale,
                  hasModeBar: modeBar != null,
                );
                Widget buildHero(double height) {
                  if (hero == null || height <= 0) {
                    return const SizedBox.shrink();
                  }
                  final showHistoryPreview = temperatureHistoryStrip != null &&
                      historyAvailable &&
                      height >= 330;
                  return KeyedSubtree(
                    key: temperatureTargetKey,
                    child: TemperatureMinimalPanel(
                      currentBind: hero.currentBind,
                      sensorsBind: hero.sensorsBind,
                      currentTargetBind: hero.currentTargetBind,
                      nextTargetBind: hero.nextTargetBind,
                      unit: '°C',
                      height: height,
                      showHistoryPreview: showHistoryPreview,
                      ultraCompact:
                          height < 300 || textScale >= 1.6 || landscape,
                      historyChartHeight: 104,
                      historyPreviewCache: _historyPreviewCache,
                      onTap: scheduleWritable
                          ? () => ThermostatModeNavigator.openForCurrentMode(
                                context,
                                availableModes: visibleModes,
                              )
                          : null,
                      onSensorActionTap: (sensor) {
                        SensorEditorNavigator.openFromHost(
                          context,
                          sensor: sensor,
                        );
                      },
                      onAddSensorTap: climateSensorPairing == null
                          ? null
                          : () => SensorPairingNavigator.openFromHost(
                                context,
                                transport: climateSensorPairing.transport,
                                timeoutSec: climateSensorPairing.timeoutSec,
                              ),
                      onOpenHistory: !historyAvailable
                          ? null
                          : (sensors, sensorId, sensorName) {
                              _historyOpener
                                  .prepareDashboard(
                                    context,
                                    title: roomName,
                                    history: bundle.configuration.history,
                                    sensors: sensors,
                                    initialSensorId: sensorId,
                                  )
                                  ?.call();
                            },
                    ),
                  );
                }

                Widget buildHeatingStatus() {
                  if (heatingStatus == null) return const SizedBox.shrink();
                  return HeatingStatusHorizontalCard(
                    bind: heatingStatus.bind,
                    onTap: () => _historyOpener.openHeating(context),
                  );
                }

                const topSpacing = 12.0;
                const sectionSpacing = 14.0;
                final bottomReservedHeight =
                    dashboardLayout.bottomReservedHeight;
                final dashboardBodyHeight = dashboardLayout.dashboardBodyHeight;
                final contentHeight = dashboardLayout.contentHeight;
                final scaledSummaryHeight = dashboardLayout.scaledSummaryHeight;

                Widget dashboardContent;
                if (landscape &&
                    constraints.maxWidth >= 680 &&
                    hero != null &&
                    heatingStatus != null) {
                  dashboardContent = Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: buildHero(contentHeight),
                      ),
                      const SizedBox(width: sectionSpacing),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: buildHeatingStatus(),
                        ),
                      ),
                    ],
                  );
                } else if (hero != null && heatingStatus != null) {
                  final summaryHeight = math.min(
                    scaledSummaryHeight,
                    contentHeight,
                  );
                  final heroHeight = math.max(
                    0.0,
                    contentHeight - summaryHeight - sectionSpacing,
                  );
                  dashboardContent = Column(
                    children: [
                      buildHero(heroHeight),
                      const SizedBox(height: sectionSpacing),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SizedBox(
                          height: summaryHeight,
                          child: buildHeatingStatus(),
                        ),
                      ),
                    ],
                  );
                } else if (hero != null) {
                  dashboardContent = buildHero(contentHeight);
                } else if (heatingStatus != null) {
                  dashboardContent = Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        height: math.min(
                          scaledSummaryHeight,
                          contentHeight,
                        ),
                        child: buildHeatingStatus(),
                      ),
                    ),
                  );
                } else {
                  dashboardContent = const SizedBox.shrink();
                }

                final dashboard = Stack(
                  children: [
                    Positioned.fill(
                      child: CustomScrollView(
                        key: const ValueKey('thermostat-dashboard-scroll'),
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          ThermostatDashboardAppBar(
                            roomName: roomName,
                            chrome: chrome,
                          ),
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: SizedBox(
                              height: dashboardBodyHeight,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  landscape ? 20 : 0,
                                  topSpacing,
                                  landscape ? 20 : 0,
                                  bottomReservedHeight,
                                ),
                                child: dashboardContent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (modeBar != null)
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 0,
                        child: SafeArea(
                          top: false,
                          minimum: const EdgeInsets.only(bottom: 12),
                          child: KeyedSubtree(
                            key: modeBarTargetKey,
                            child: ThermostatModeBar(
                              modeBind: modeBar.modeBind,
                              visibleModes: visibleModes,
                              writable: scheduleWritable,
                            ),
                          ),
                        ),
                      ),
                  ],
                );

                if (!hasLiveMetrics) return dashboard;

                final s = S.of(context);
                return ThermostatLiveMetricsOverlay(
                  dashboard: dashboard,
                  foregroundBuilder: (context, interactionController) {
                    return ThermostatLiveMetricsGuideGate(
                      cubit: userGuideCubit,
                      interactionController: interactionController,
                      modeBarTargetKey: modeBar == null || !scheduleWritable
                          ? null
                          : modeBarTargetKey,
                      temperatureTargetKey: hero == null || !scheduleWritable
                          ? null
                          : temperatureTargetKey,
                      onOpenModeSettings: modeBar == null || !scheduleWritable
                          ? null
                          : () => ThermostatModeNavigator.openForCurrentMode(
                                context,
                                availableModes: visibleModes,
                              ),
                      onOpenTemperatureSettings: hero == null ||
                              !scheduleWritable
                          ? null
                          : () => ThermostatModeNavigator.openForCurrentMode(
                                context,
                                availableModes: visibleModes,
                              ),
                    );
                  },
                  contentBuilder: (
                    context,
                    scrollController,
                    close,
                    titleFocusNode,
                  ) {
                    return ThermostatLiveMetricsSheet(
                      title: s.ThermostatLiveMetricsTitle,
                      deviceTitle: roomName,
                      closeTooltip: s.ThermostatLiveMetricsCloseTooltip,
                      tiles: schema.tiles,
                      scrollController: scrollController,
                      onClose: close,
                      titleFocusNode: titleFocusNode,
                      openHistoryLabel: s.ThermostatLiveMetricsShowHistory,
                      openHistoryTooltip:
                          s.ThermostatLiveMetricsShowHistoryTooltip,
                      onOpenHistory: configuredHistoryAction,
                      tileBuilder: (context, index) =>
                          _buildTile(context, device, schema.tiles[index]),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  List<DeviceTemperatureSensorRef> _historySensors(
    DeviceSnapshot snapshot,
    ThermostatHeroSpec? hero,
  ) {
    if (hero == null) return const <DeviceTemperatureSensorRef>[];
    final controlState =
        snapshot.controlState.data ?? const <String, dynamic>{};
    final sensors = TemperatureSensorsResolver().resolve(
      readBind(controlState, hero.sensorsBind),
    );
    return temperatureHistorySensorRefs(sensors);
  }

  String _historySensorSignature(
    DeviceSnapshot snapshot,
    ThermostatHeroSpec? hero,
  ) {
    return _historySensors(snapshot, hero)
        .map((sensor) =>
            '${sensor.id}\u0000${sensor.name}\u0000${sensor.isReference}')
        .join('\u0001');
  }

  String? _referenceSensorId(List<DeviceTemperatureSensorRef> sensors) {
    for (final sensor in sensors) {
      if (sensor.isReference) return sensor.id;
    }
    return null;
  }

  Widget _buildTile(
    BuildContext context,
    Device device,
    ThermostatTileSpec tile,
  ) {
    switch (tile) {
      case ThermostatDailyEnergyTileSpec():
        return DailyEnergyUsageCard(
          title: S.of(context).TelemetryHistoryMetricEnergyUsed,
          cache: _dailyEnergyCache,
          cacheNamespace:
              device.sn.trim().isEmpty ? device.id : device.sn.trim(),
          onTap: () => _historyOpener.openEnergyUsage(context),
        );
      case ThermostatDailyHeatingTileSpec():
        return DailyHeatingUsageCard(
          title: S.of(context).TelemetryHistoryMetricLoadFactor,
          onTap: () => _historyOpener.openLoadFactor(context),
        );
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
          onTap: () => _historyOpener.openHeating(context),
        );
      case ThermostatTileType.loadFactor24h:
        return const SizedBox.shrink();
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
      case ThermostatTileType.energyUsed:
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

String _resolveDeviceTitle(Device device) {
  final alias = device.userData.alias.trim();
  if (alias.isNotEmpty) return alias;

  final serial = device.sn.trim();
  if (serial.isNotEmpty) return serial;

  final modelName = device.modelName.trim();
  if (modelName.isNotEmpty) return modelName;

  final modelId = device.modelId.trim();
  if (modelId.isNotEmpty) return modelId;

  final id = device.id.trim();
  return id.isEmpty ? 'Osh App' : id;
}
