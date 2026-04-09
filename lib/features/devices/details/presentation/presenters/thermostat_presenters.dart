import 'package:flutter/material.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/configuration/models/device_configuration_bundle.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/temperature_minimal_panel.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/temperature_history_strip_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/thermostat_mode_bar.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/delta_temp_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/heating_status_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/inlet_temp_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/load_factor_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/outlet_temp_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/power_card.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';
import 'package:oshmobile/features/schedule/presentation/open_mode_editor.dart';
import 'package:oshmobile/features/sensors/presentation/open_sensor_editor.dart';
import 'package:oshmobile/features/telemetry_history/presentation/open_telemetry_history.dart';

import 'device_presenter.dart';

class ThermostatBasicPresenter implements DevicePresenter {
  const ThermostatBasicPresenter();

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
    const gridChildAspectRatio = 1.1;
    final contentWidth =
        MediaQuery.sizeOf(context).width - horizontalPadding * 2;
    final tileWidth =
        (contentWidth - gridCrossAxisSpacing * (gridCrossAxisCount - 1)) /
            gridCrossAxisCount;
    final statTileHeight = tileWidth / gridChildAspectRatio;

    final tiles = _buildTiles(context, bundle);
    final showHero = bundle.canRenderWidget('heroTemperature');
    final showModeBar = bundle.canRenderWidget('modeBar');
    final visibleModes = _visibleModes(bundle);
    final scheduleWritable = bundle.canPatchDomain('schedule');
    final heroCurrentBind = _widgetControl(bundle, 'heroTemperature', 0);
    final heroCurrentTargetBind = _widgetControl(bundle, 'heroTemperature', 1);
    final heroNextTargetBind = _widgetControl(bundle, 'heroTemperature', 2);
    final heroSensorsBind = _widgetControl(bundle, 'heroTemperature', 3);
    final modeBind = _widgetControl(bundle, 'modeBar', 0);

    return Scaffold(
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (showHero)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
                  child: TemperatureMinimalPanel(
                    currentBind: heroCurrentBind,
                    sensorsBind: heroSensorsBind,
                    currentTargetBind: heroCurrentTargetBind,
                    nextTargetBind: heroNextTargetBind,
                    unit: '°C',
                    height: MediaQuery.sizeOf(context).height * 0.38,
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
            if (showModeBar)
              SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: ThermostatModeBar(
                      modeBind: modeBind,
                      visibleModes: visibleModes,
                      writable: scheduleWritable,
                    )),
              ),
            if (showHero && heroSensorsBind.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      horizontalPadding, 12, horizontalPadding, 0),
                  child: TemperatureHistoryStripCard(
                    sensorsBind: heroSensorsBind,
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
                  [for (final tile in tiles) tile.builder()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @visibleForTesting
  static List<String> visibleWidgetIds(DeviceConfigurationBundle bundle) {
    final ids = <String>[];
    for (final widgetId in const [
      'heroTemperature',
      'modeBar',
      'heatingToggle',
      'loadFactor24h',
      'powerNow',
      'inletTemp',
      'outletTemp',
      'deltaT',
    ]) {
      if (bundle.canRenderWidget(widgetId)) {
        ids.add(widgetId);
      }
    }
    return ids;
  }

  List<_Tile> _buildTiles(
      BuildContext context, DeviceConfigurationBundle bundle) {
    final tiles = <_Tile>[];

    if (bundle.canRenderWidget('heatingToggle')) {
      final bind = _widgetControl(bundle, 'heatingToggle', 0);
      tiles.add(
        _Tile(
          id: 'heatingToggle',
          builder: () => HeatingStatusCard(
            bind: bind,
            title: 'Heating',
            onTap: () => TelemetryHistoryNavigator.openHeatingFromHost(context),
          ),
        ),
      );
    }

    if (bundle.canRenderWidget('loadFactor24h')) {
      final bind = _widgetControl(bundle, 'loadFactor24h', 0);
      tiles.add(
        _Tile(
          id: 'loadFactor24h',
          builder: () => LoadFactorKpiCard(
            percentBind: bind,
            onTap: () =>
                TelemetryHistoryNavigator.openLoadFactorFromHost(context),
          ),
        ),
      );
    }

    if (bundle.canRenderWidget('powerNow')) {
      final bind = _widgetControl(bundle, 'powerNow', 0);
      tiles.add(
        _Tile(
          id: 'powerNow',
          builder: () => PowerCard(bind: bind),
        ),
      );
    }

    if (bundle.canRenderWidget('inletTemp')) {
      final bind = _widgetControl(bundle, 'inletTemp', 0);
      tiles.add(
        _Tile(
          id: 'inletTemp',
          builder: () => InletTempCard(bind: bind),
        ),
      );
    }

    if (bundle.canRenderWidget('outletTemp')) {
      final bind = _widgetControl(bundle, 'outletTemp', 0);
      tiles.add(
        _Tile(
          id: 'outletTemp',
          builder: () => OutletTempCard(bind: bind),
        ),
      );
    }

    if (bundle.canRenderWidget('deltaT')) {
      final inletBind = _widgetControl(bundle, 'deltaT', 0);
      final outletBind = _widgetControl(bundle, 'deltaT', 1);
      tiles.add(
        _Tile(
          id: 'deltaT',
          builder: () => DeltaTCard(
            inletBind: inletBind,
            outletBind: outletBind,
            unit: '°C',
          ),
        ),
      );
    }

    return tiles;
  }

  List<CalendarMode>? _visibleModes(DeviceConfigurationBundle bundle) {
    final ids = bundle.widget('modeBar')?.modes ?? const <String>[];
    if (ids.isEmpty) return null;

    final all = <String, CalendarMode>{
      for (final mode in CalendarMode.all) mode.id: mode,
    };

    return ids
        .map((id) => all[id])
        .whereType<CalendarMode>()
        .toList(growable: false);
  }

  String _widgetControl(
    DeviceConfigurationBundle bundle,
    String widgetId,
    int index,
  ) {
    final widget = bundle.widget(widgetId);
    if (widget == null || index >= widget.controlIds.length) {
      return '';
    }
    return widget.controlIds[index];
  }
}

class _Tile {
  final String id;
  final Widget Function() builder;

  const _Tile({required this.id, required this.builder});
}
