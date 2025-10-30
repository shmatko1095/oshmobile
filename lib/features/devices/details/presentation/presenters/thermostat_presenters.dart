import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/temperature_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/temperature_minimal_panel.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/thermostat_mode_bar.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/delta_temp_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/inlet_temp_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/load_factor_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/outlet_temp_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/power_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/slider_setting.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/toggle_tile.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/value_card.dart';
import 'package:oshmobile/features/schedule/presentation/open_mode_editor.dart';

import '../cubit/device_actions_cubit.dart';
import '../models/osh_config.dart';
import 'device_presenter.dart';

class ThermostatBasicPresenter implements DevicePresenter {
  const ThermostatBasicPresenter();

  @override
  Widget build(BuildContext context, Device device, OshConfig cfg) {
    final tiles = <_Tile>[
      _Tile(
        id: 'currentHumidity',
        cap: 'sensor.humidity',
        builder: () => ValueCard(bind: 'sensor.humidity', title: 'Humidity', suffix: '%'),
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
      _Tile(
        id: 'powerNow',
        cap: 'sensor.power', // измени под свой capability
        builder: () => const PowerCard(bind: 'sensor.power'),
      ),
      _Tile(
        id: 'loadFactor24h',
        cap: 'stats.heating_duty_24h', // или 'stats.heating_on_hours_24h' — под свой конфиг
        builder: () => const LoadFactorCard(
          percentBind: 'stats.heating_duty_24h', // 0..1 или 0..100
        ),
      ),
      _Tile(
        id: 'inletTemp',
        cap: 'sensor.water_inlet_temp',
        builder: () => const InletTempCard(bind: 'sensor.water_inlet_temp'),
      ),
      _Tile(
        id: 'outletTemp',
        cap: 'sensor.water_outlet_temp',
        builder: () => const OutletTempCard(bind: 'sensor.water_outlet_temp'),
      ),
    ];

    if (cfg.has('sensor.water_inlet_temp') && cfg.has('sensor.water_outlet_temp')) {
      tiles.add(
        _Tile(
          id: 'deltaT',
          cap: 'sensor.water_inlet_temp', // любой из двух, чтобы пройти фильтр
          builder: () => const DeltaTCard(
            inletBind: 'sensor.water_inlet_temp',
            outletBind: 'sensor.water_outlet_temp',
            unit: '°C',
          ),
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
        slivers: [
          if (canShowHero)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: TemperatureMinimalPanel(
                    currentBind: 'chipTemp',
                    targetBind: 'setting.target_temperature',
                    nextValueBind: 'schedule.next_target_temperature',
                    nextTimeBind: 'schedule.next_time',
                    heaterEnabledBind: 'switch.heating.state',
                    unit: '°C',
                    height: MediaQuery.sizeOf(context).height * 0.38,
                    onTap: () {
                      openThermostatModeEditor(
                        context,
                        deviceId: device.id,
                        // можно переопределить команды/бинды при необходимости:
                        // manualTargetBind: 'setting.target_temperature',
                        // antifreezeMinBind: 'antifreeze.min_temperature',
                        // antifreezeMaxBind: 'antifreeze.max_temperature',
                        // manualCommand: 'climate.set_target_temperature',
                        // antifreezeCommand: 'climate.set_antifreeze_range',
                        // scheduleRepository: DeviceActionsScheduleRepository(context.read<DeviceActionsCubit>()),
                      );

                      // final deviceStateCubit = context.read<DeviceStateCubit>();
                      // final actionsCubit = context.read<DeviceActionsCubit>();

                      // Navigator.of(context).push(
                      //   MaterialPageRoute(
                      //     builder: (_) => MultiBlocProvider(
                      //       providers: [
                      //         BlocProvider.value(value: deviceStateCubit),
                      //
                      //         // Если нужен actions на экране (например, DeviceActionsScheduleRepository):
                      //         // BlocProvider.value(value: actionsCubit),
                      //         BlocProvider(
                      //           create: (_) => ScheduleCubit(
                      //             repo: InMemoryScheduleRepository(), // или твой DeviceActionsScheduleRepository(...)
                      //             deviceId: device.id,
                      //           ),
                      //         ),
                      //       ],
                      //       child: ScheduleEditorPage(deviceId: device.id),
                      //     ),
                      //   ),
                      // );
                    }),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: TemperatureHeroCard(
                title: "Sensor name",
                //TODO
                currentBind: 'chipTemp',
                targetBind: 'setting.target_temperature',
                nextValueBind: 'schedule.next_target_temperature',
                nextTimeBind: 'schedule.next_time',
                heaterEnabledBind: 'switch.heating.state',
                humidityBind: 'sensor.humidity',
                unit: '°C',
              ),
            ),
          ),
          if (canShowHero)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: ThermostatModeBar(
                  deviceId: device.id,
                  bind: 'climate.mode',
                  command: 'climate.set_mode',
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
