import 'package:flutter/material.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/profile/models/device_profile_bundle.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/temperature_minimal_panel.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/thermostat_mode_bar.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/delta_temp_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/heating_status_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/inlet_temp_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/load_factor_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/outlet_temp_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/power_card.dart';
import 'package:oshmobile/features/schedule/presentation/open_mode_editor.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';

import 'device_presenter.dart';

class ThermostatBasicPresenter implements DevicePresenter {
  const ThermostatBasicPresenter();

  @override
  Widget build(
      BuildContext context, Device device, DeviceProfileBundle bundle) {
    final tiles = _buildTiles(bundle);
    final showHero = bundle.canRenderWidget('heroTemperature');
    final showModeBar = bundle.canRenderWidget('modeBar');
    final visibleModes = _visibleModes(bundle);
    final scheduleWritable =
        bundle.canPatchDomain('schedule') || bundle.canSetDomain('schedule');

    return Scaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (showHero)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
                child: TemperatureMinimalPanel(
                  currentBind: 'ambient_temperature',
                  sensorsBind: 'telemetry_climate_sensors',
                  currentTargetBind: 'schedule_current_target_temp',
                  nextTargetBind: 'schedule_next_target_temp',
                  unit: '°C',
                  height: MediaQuery.sizeOf(context).height * 0.38,
                  onTap: scheduleWritable
                      ? () =>
                          ThermostatModeNavigator.openForCurrentMode(context)
                      : null,
                ),
              ),
            ),
          if (showModeBar)
            SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: ThermostatModeBar(
                    visibleModes: visibleModes,
                    writable: scheduleWritable,
                  )),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              delegate: SliverChildListDelegate(
                [for (final tile in tiles) tile.builder()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @visibleForTesting
  static List<String> visibleWidgetIds(DeviceProfileBundle bundle) {
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

  List<_Tile> _buildTiles(DeviceProfileBundle bundle) {
    final tiles = <_Tile>[];

    if (bundle.canRenderWidget('heatingToggle')) {
      tiles.add(
        _Tile(
          id: 'heatingToggle',
          builder: () => const HeatingStatusCard(
            bind: 'heater_enabled',
            title: 'Heating',
          ),
        ),
      );
    }

    if (bundle.canRenderWidget('loadFactor24h')) {
      tiles.add(
        _Tile(
          id: 'loadFactor24h',
          builder: () => const LoadFactorKpiCard(
            percentBind: 'heating_activity_24h',
          ),
        ),
      );
    }

    if (bundle.canRenderWidget('powerNow')) {
      tiles.add(
        _Tile(
          id: 'powerNow',
          builder: () => const PowerCard(bind: 'power_now'),
        ),
      );
    }

    if (bundle.canRenderWidget('inletTemp')) {
      tiles.add(
        _Tile(
          id: 'inletTemp',
          builder: () => const InletTempCard(bind: 'water_inlet_temperature'),
        ),
      );
    }

    if (bundle.canRenderWidget('outletTemp')) {
      tiles.add(
        _Tile(
          id: 'outletTemp',
          builder: () => const OutletTempCard(bind: 'water_outlet_temperature'),
        ),
      );
    }

    if (bundle.canRenderWidget('deltaT')) {
      tiles.add(
        _Tile(
          id: 'deltaT',
          builder: () => const DeltaTCard(
            inletBind: 'water_inlet_temperature',
            outletBind: 'water_outlet_temperature',
            unit: '°C',
          ),
        ),
      );
    }

    return tiles;
  }

  List<CalendarMode>? _visibleModes(DeviceProfileBundle bundle) {
    final ids = bundle.modelProfile.osh.scheduleModes;
    if (ids.isEmpty) return null;

    final all = <String, CalendarMode>{
      for (final mode in CalendarMode.all) mode.id: mode,
    };

    return ids.map((id) => all[id]).whereType<CalendarMode>().where((mode) {
      if (mode != CalendarMode.range) return true;
      return bundle.supportsFeature('schedule', 'range-mode');
    }).toList(growable: false);
  }
}

class _Tile {
  final String id;
  final Widget Function() builder;

  const _Tile({required this.id, required this.builder});
}
