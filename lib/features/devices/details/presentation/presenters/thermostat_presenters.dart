import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/slider_setting.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/temperature_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/toggle_tile.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/value_card.dart';

import '../cubit/device_actions_cubit.dart';
import '../models/osh_config.dart';
import 'device_presenter.dart';

class ThermostatBasicPresenter implements DevicePresenter {
  const ThermostatBasicPresenter();

  @override
  Widget build(BuildContext context, Device device, OshConfig cfg) {
    final tiles = <_Tile>[
      _Tile(
        id: 'currentTemp',
        cap: 'sensor.temperature',
        builder: () => ValueCard(bind: 'sensor.temperature', title: 'Temperature', suffix: '°C'),
      ),
      _Tile(
        id: 'targetTemp',
        cap: 'setting.target_temperature',
        builder: () => SliderSetting(
          bind: 'setting.target_temperature',
          title: 'Target temperature',
          min: 5,
          max: 35,
          step: 0.5,
          onSubmit: (ctx, v) => ctx
              .read<DeviceActionsCubit>()
              .sendCommand(device.id, 'climate.set_target_temperature', args: {'value': v}),
        ),
      ),
      _Tile(
        id: 'heatingToggle',
        cap: 'switch.heating',
        builder: () => ToggleTile(
          bind: 'switch.heating.state',
          title: 'Heating',
          onChanged: (ctx, v) =>
              ctx.read<DeviceActionsCubit>().sendCommand(device.id, 'switch.heating.set', args: {'state': v}),
        ),
      ),
    ];

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

    final alias = device.userData.alias.isEmpty ? device.sn : device.userData.alias;
    final canShowHero = cfg.has('sensor.temperature') || cfg.has('setting.target_temperature');

    return Scaffold(
      // appBar: AppBar(title: Text(alias)),
      body: CustomScrollView(
        slivers: [
          if (canShowHero)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: TemperatureHeroCard(
                  title: "Sensor name", //TODO
                  currentBind: 'sensor.temperature',
                  targetBind: 'setting.target_temperature',
                  nextValueBind: 'schedule.next_target_temperature',
                  nextTimeBind: 'schedule.next_time',
                  heaterEnabledBind: 'status.heater_enabled',
                  unit: '°C',
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildListDelegate([
                for (final t in show) t.builder(),
              ]),
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
