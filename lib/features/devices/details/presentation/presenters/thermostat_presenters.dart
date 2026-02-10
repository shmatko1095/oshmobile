import 'package:flutter/material.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/network/mqtt/profiles/thermostat/thermostat_signals.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/temperature_minimal_panel.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/thermostat_mode_bar.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/delta_temp_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/inlet_temp_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/load_factor_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/outlet_temp_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/power_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/toggle_tile.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/value_card.dart';
import 'package:oshmobile/features/schedule/presentation/open_mode_editor.dart';

import '../models/osh_config.dart';
import 'device_presenter.dart';

class ThermostatBasicPresenter implements DevicePresenter {
  const ThermostatBasicPresenter();

  @override
  Widget build(BuildContext context, Device device, DeviceConfig cfg) {
    final tiles = <_Tile>[
      _Tile(
          id: 'currentHumidity',
          cap: 'sensor.humidity',
          builder: () => ValueCard(bind: ThermostatSignals.sensorHumidity, title: 'Humidity', suffix: '%')),
      // _Tile(
      //     id: 'targetTemp',
      //     cap: 'setting.target_temperature',
      //     builder: () => SliderSetting(
      //           bind: ThermostatSignals.settingTargetTemp,
      //           title: 'Target temperature',
      //           min: 5,
      //           max: 35,
      //           step: 0.5,
      //           onSubmit: (ctx, v) => {},
      //         )),
      _Tile(
        id: 'heatingToggle',
        cap: 'switch.heating',
        builder: () => ToggleTile(
            bind: ThermostatSignals.settingSwitchHeatingState,
            title: 'Heating',
            onChanged: null),
      ),
      _Tile(id: 'powerNow', cap: 'sensor.power', builder: () => const PowerCard(bind: ThermostatSignals.sensorPower)),
      _Tile(
          id: 'loadFactor24h',
          cap: 'stats.heating_duty_24h',
          builder: () => const LoadFactorCard(percentBind: ThermostatSignals.statsPower)),
      _Tile(
          id: 'inletTemp',
          cap: 'sensor.water_inlet_temp',
          builder: () => const InletTempCard(bind: ThermostatSignals.sensorWaterInletTemp)),
      _Tile(
          id: 'outletTemp',
          cap: 'sensor.water_outlet_temp',
          builder: () => const OutletTempCard(bind: ThermostatSignals.sensorWaterOutletTemp)),
    ];

    if (cfg.has('sensor.water_inlet_temp') && cfg.has('sensor.water_outlet_temp')) {
      tiles.add(
        _Tile(
          id: 'deltaT',
          cap: 'sensor.water_inlet_temp',
          builder: () => const DeltaTCard(
              inletBind: ThermostatSignals.sensorWaterInletTemp,
              outletBind: ThermostatSignals.sensorWaterOutletTemp,
              unit: '°C'),
        ),
      );
    }

    var show = tiles.where((t) => cfg.has(t.cap) && cfg.visible(t.id)).toList();
    if (cfg.order.isNotEmpty) {
      show.sort((a, b) {
        int ia = cfg.order.indexOf(a.id);
        if (ia == -1) ia = 1 << 30;
        int ib = cfg.order.indexOf(b.id);
        if (ib == -1) ib = 1 << 30;
        return ia.compareTo(ib);
      });
    }

    final canShowHero = cfg.has('sensor.temperature') || cfg.has('setting.target_temperature');

    return Scaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (canShowHero)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: TemperatureMinimalPanel(
                    currentBind: ThermostatSignals.telemetrySignal,
                    heaterEnabledBind: ThermostatSignals.settingSwitchHeatingState,
                    unit: '°C',
                    height: MediaQuery.sizeOf(context).height * 0.38,
                    onTap: () => ThermostatModeNavigator.openForCurrentMode(context)),
              ),
            ),
          if (canShowHero)
            SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: const ThermostatModeBar()),
            ),
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildListDelegate([for (final t in show) t.builder()]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile {
  final String id, cap;
  final Widget Function() builder;

  const _Tile({required this.id, required this.cap, required this.builder});
}
