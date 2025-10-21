import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';

import '../cubit/device_actions_cubit.dart';
import '../cubit/device_state_cubit.dart';
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
        builder: () => _ValueCard(bind: 'sensor.temperature', title: 'Temperature', suffix: '°C'),
      ),
      _Tile(
        id: 'targetTemp',
        cap: 'setting.target_temperature',
        builder: () => _SliderSetting(
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
        builder: () => _ToggleTile(
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

    return Scaffold(
      appBar: AppBar(title: Text(device.userData.alias.isEmpty ? device.sn : device.userData.alias)),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [for (final t in show) t.builder()],
        ),
      ),
    );
  }
}

class _Tile {
  final String id, cap;
  final Widget Function() builder;

  const _Tile({required this.id, required this.cap, required this.builder});
}

class _ValueCard extends StatelessWidget {
  final String title, bind;
  final String? suffix;

  const _ValueCard({super.key, required this.title, required this.bind, this.suffix});

  @override
  Widget build(BuildContext context) {
    final v = context.select<DeviceStateCubit, dynamic>((c) => c.state.valueOf(bind));
    final text = v == null ? '—' : v.toString();
    return Card(
        child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('$text${suffix ?? ''}', style: const TextStyle(fontSize: 18)),
      ]),
    ));
  }
}

class _ToggleTile extends StatelessWidget {
  final String title, bind;
  final void Function(BuildContext, bool) onChanged;

  const _ToggleTile({super.key, required this.title, required this.bind, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final value = (context.select<DeviceStateCubit, dynamic>((c) => c.state.valueOf(bind)) as bool?) ?? false;
    return Card(
        child: Padding(
      padding: const EdgeInsets.all(8),
      child: SwitchListTile(title: Text(title), value: value, onChanged: (v) => onChanged(context, v)),
    ));
  }
}

class _SliderSetting extends StatefulWidget {
  final String title, bind;
  final double min, max, step;
  final void Function(BuildContext, double) onSubmit;

  const _SliderSetting(
      {super.key,
      required this.title,
      required this.bind,
      required this.min,
      required this.max,
      required this.step,
      required this.onSubmit});

  @override
  State<_SliderSetting> createState() => _SliderSettingState();
}

class _SliderSettingState extends State<_SliderSetting> {
  double? _val;

  @override
  Widget build(BuildContext context) {
    final current =
        (context.select<DeviceStateCubit, dynamic>((c) => c.state.valueOf(widget.bind)) as num?)?.toDouble() ??
            (widget.min + widget.max) / 2;
    final v = _val ?? current;
    return Card(
        child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${widget.title}: ${v.toStringAsFixed(1)}'),
        Slider(
          value: v,
          min: widget.min,
          max: widget.max,
          onChanged: (x) => setState(() => _val = x),
          onChangeEnd: (x) => widget.onSubmit(context, x),
        ),
      ]),
    ));
  }
}
