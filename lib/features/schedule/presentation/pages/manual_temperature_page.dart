import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/auth/presentation/widgets/elevated_button.dart';
import 'package:oshmobile/generated/l10n.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';

bool _manualTempIsDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color _manualTempPrimaryTextColor(BuildContext context) =>
    _manualTempIsDark(context)
        ? AppPalette.textPrimary
        : AppPalette.lightTextPrimary;

class ManualTemperaturePage extends StatefulWidget {
  const ManualTemperaturePage({
    super.key,
    required this.initial,
    required this.onSave,
    required this.title,
    this.min = 10.0,
    this.max = 40.0,
    this.step = 0.5,
    this.unit = '°C',
    this.supportedSetpointKinds = const <ScheduleSetpointKind>{
      ScheduleSetpointKind.temperature,
    },
  });

  final ScheduleSetpoint initial;
  final void Function(ScheduleSetpoint value) onSave;

  final double min, max, step;
  final String title, unit;
  final Set<ScheduleSetpointKind> supportedSetpointKinds;

  @override
  State<ManualTemperaturePage> createState() => _ManualTemperaturePageState();
}

class _ManualTemperaturePageState extends State<ManualTemperaturePage> {
  late final List<ScheduleSetpoint> _values;
  late int _index;

  @override
  void initState() {
    super.initState();
    _values = <ScheduleSetpoint>[
      if (widget.supportedSetpointKinds.contains(ScheduleSetpointKind.off))
        const ScheduleSetpoint.off(),
      for (double v = widget.min; v <= widget.max + 1e-6; v += widget.step)
        ScheduleSetpoint.temperature(double.parse(v.toStringAsFixed(1))),
      if (widget.supportedSetpointKinds.contains(ScheduleSetpointKind.on))
        const ScheduleSetpoint.on(),
    ];
    _index = _closestIndex(widget.initial);
  }

  int _closestIndex(ScheduleSetpoint value) {
    if (value.isOff &&
        widget.supportedSetpointKinds.contains(ScheduleSetpointKind.off)) {
      return 0;
    }
    if (value.isOn &&
        widget.supportedSetpointKinds.contains(ScheduleSetpointKind.on)) {
      return _values.length - 1;
    }
    final x = value.temperature ?? widget.min;
    int best = 0;
    double bestDist = double.infinity;
    for (int i = 0; i < _values.length; i++) {
      final candidate = _values[i].temperature;
      if (candidate == null) continue;
      final d = (candidate - x).abs();
      if (d < bestDist) {
        best = i;
        bestDist = d;
      }
    }
    return best;
  }

  void _onSave(BuildContext context) {
    final value = _values[_index];
    widget.onSave(value);
    Navigator.pop(context);
  }

  String _fmt(ScheduleSetpoint value) {
    if (value.isOn) return 'ON';
    if (value.isOff) return 'OFF';
    return '${value.temperature!.toStringAsFixed(1)}${widget.unit}';
  }

  String _fmtRoller(ScheduleSetpoint value) {
    if (value.isOn) return 'ON';
    if (value.isOff) return 'OFF';
    return value.temperature!.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppPalette.transparent,
        elevation: 0,
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 160),
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w600,
                color: _manualTempPrimaryTextColor(context),
              ),
              child: Semantics(
                liveRegion: true,
                label: _fmt(_values[_index]),
                child: Text(_fmt(_values[_index])),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Semantics(
                label: 'Schedule setpoint picker',
                value: _fmt(_values[_index]),
                child: CupertinoPicker(
                  itemExtent: 68,
                  diameterRatio: 1.5,
                  magnification: 1.1,
                  scrollController:
                      FixedExtentScrollController(initialItem: _index),
                  selectionOverlay:
                      const CupertinoPickerDefaultSelectionOverlay(
                    background: AppPalette.transparent,
                  ),
                  onSelectedItemChanged: (i) => setState(() => _index = i),
                  children: [
                    for (final v in _values)
                      Center(
                        child: Text(
                          _fmtRoller(v),
                          style: TextStyle(
                            color: _manualTempPrimaryTextColor(context),
                            fontSize: 36,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: CustomElevatedButton(
                buttonText: S.of(context).Save,
                onPressed: () => _onSave(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
