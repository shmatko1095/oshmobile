import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_state_cubit.dart';

class SliderSetting extends StatefulWidget {
  final String title, bind;
  final double min, max, step;
  final void Function(BuildContext, double) onSubmit;

  const SliderSetting(
      {super.key,
      required this.title,
      required this.bind,
      required this.min,
      required this.max,
      required this.step,
      required this.onSubmit});

  @override
  State<SliderSetting> createState() => _SliderSettingState();
}

class _SliderSettingState extends State<SliderSetting> {
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
