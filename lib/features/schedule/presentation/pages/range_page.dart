import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:oshmobile/features/auth/presentation/widgets/elevated_button.dart';
import 'package:oshmobile/generated/l10n.dart';

class ScheduleRangePage extends StatefulWidget {
  const ScheduleRangePage({
    super.key,
    required this.initialMin,
    required this.initialMax,
    required this.onSave,
    required this.title,
    this.min = 5.0,
    this.max = 35.0,
    this.step = 0.5,
    this.unit = '°C',
  });

  final double initialMin, initialMax;
  final void Function(double minValue, double maxValue) onSave;

  final double min, max, step;
  final String title, unit;

  @override
  State<ScheduleRangePage> createState() => _ScheduleRangePageState();
}

class _ScheduleRangePageState extends State<ScheduleRangePage> {
  late final List<double> _values;
  late int _iMin, _iMax;

  late final FixedExtentScrollController _minCtrl;
  late final FixedExtentScrollController _maxCtrl;

  static const _animDur = Duration(milliseconds: 180);
  static const _animCurve = Curves.easeOut;

  @override
  void initState() {
    super.initState();
    _values = [
      for (double v = widget.min; v <= widget.max + 1e-6; v += widget.step) double.parse(v.toStringAsFixed(1)),
    ];

    _iMin = _closestIndex(widget.initialMin);
    _iMax = _closestIndex(widget.initialMax);

    if (_iMin > _iMax) {
      final t = _iMin;
      _iMin = _iMax;
      _iMax = t;
    }

    _minCtrl = FixedExtentScrollController(initialItem: _iMin);
    _maxCtrl = FixedExtentScrollController(initialItem: _iMax);
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  void _onSave(BuildContext context) {
    final minV = _values[_iMin];
    final maxV = _values[_iMax];

    final a = _iMin <= _iMax ? minV : _values[_iMax];
    final b = _iMin <= _iMax ? maxV : _values[_iMin];
    widget.onSave(a, b);
    Navigator.pop(context);
  }

  int _closestIndex(double x) {
    int best = 0;
    double bestDist = double.infinity;
    for (int i = 0; i < _values.length; i++) {
      final d = (_values[i] - x).abs();
      if (d < bestDist) {
        best = i;
        bestDist = d;
      }
    }
    return best;
  }

  String _fmt(double v) => v.toStringAsFixed(1);

  void _setMinIndex(int i) {
    _iMin = i;

    if (_iMin >= _iMax) {
      final target = (_iMin < _values.length - 1) ? _iMin + 1 : _iMin;
      if (target != _iMax) {
        _iMax = target;
        _maxCtrl.animateToItem(_iMax, duration: _animDur, curve: _animCurve);
      }
    }
    setState(() {});
  }

  void _setMaxIndex(int i) {
    _iMax = i;

    if (_iMax <= _iMin) {
      final target = (_iMax > 0) ? _iMax - 1 : _iMax;
      if (target != _iMin) {
        _iMin = target;
        _minCtrl.animateToItem(_iMin, duration: _animDur, curve: _animCurve);
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _pill('Min', '${_fmt(_values[_iMin])}${widget.unit}'),
                const SizedBox(width: 12),
                _pill('Max', '${_fmt(_values[_iMax])}${widget.unit}'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _PickerColumn(
                      label: 'Min',
                      controller: _minCtrl,
                      values: _values,
                      onChanged: _setMinIndex,
                    ),
                  ),
                  const VerticalDivider(width: 1, thickness: 0.5, color: Colors.white24),
                  Expanded(
                    child: _PickerColumn(
                      label: 'Max',
                      controller: _maxCtrl,
                      values: _values,
                      onChanged: _setMaxIndex,
                    ),
                  ),
                ],
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

  Widget _pill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _PickerColumn extends StatelessWidget {
  const _PickerColumn({
    required this.label,
    required this.controller,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final FixedExtentScrollController controller;
  final List<double> values;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white70)),
        Expanded(
          child: CupertinoPicker(
            itemExtent: 68,
            diameterRatio: 1.5,
            magnification: 1.1,
            scrollController: controller,
            selectionOverlay: const CupertinoPickerDefaultSelectionOverlay(background: Colors.transparent),
            onSelectedItemChanged: onChanged,
            children: [
              for (final v in values)
                Center(
                  child: Text(
                    v.toStringAsFixed(1),
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
