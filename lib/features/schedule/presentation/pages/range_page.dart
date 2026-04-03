import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:oshmobile/features/auth/presentation/widgets/elevated_button.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/generated/l10n.dart';

bool _rangeIsDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color _rangeBorderColor(BuildContext context) =>
    _rangeIsDark(context) ? AppPalette.borderSoft : AppPalette.lightBorder;

Color _rangePrimaryTextColor(BuildContext context) => _rangeIsDark(context)
    ? AppPalette.textPrimary
    : AppPalette.lightTextPrimary;

Color _rangeSecondaryTextColor(BuildContext context) => _rangeIsDark(context)
    ? AppPalette.textSecondary
    : AppPalette.lightTextSecondary;

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
      for (double v = widget.min; v <= widget.max + 1e-6; v += widget.step)
        double.parse(v.toStringAsFixed(1)),
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
                color: _rangePrimaryTextColor(context),
              ),
              child: Text(
                '${_fmt(_values[_iMin])} - ${_fmt(_values[_iMax])}${widget.unit}',
              ),
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
                      primaryTextColor: _rangePrimaryTextColor(context),
                      secondaryTextColor: _rangeSecondaryTextColor(context),
                    ),
                  ),
                  VerticalDivider(
                    width: 1,
                    thickness: 0.5,
                    color: _rangeBorderColor(context),
                  ),
                  Expanded(
                    child: _PickerColumn(
                      label: 'Max',
                      controller: _maxCtrl,
                      values: _values,
                      onChanged: _setMaxIndex,
                      primaryTextColor: _rangePrimaryTextColor(context),
                      secondaryTextColor: _rangeSecondaryTextColor(context),
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
}

class _PickerColumn extends StatelessWidget {
  const _PickerColumn({
    required this.label,
    required this.controller,
    required this.values,
    required this.onChanged,
    required this.primaryTextColor,
    required this.secondaryTextColor,
  });

  final String label;
  final FixedExtentScrollController controller;
  final List<double> values;
  final ValueChanged<int> onChanged;
  final Color primaryTextColor;
  final Color secondaryTextColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: secondaryTextColor)),
        Expanded(
          child: CupertinoPicker(
            itemExtent: 68,
            diameterRatio: 1.5,
            magnification: 1.1,
            scrollController: controller,
            selectionOverlay: const CupertinoPickerDefaultSelectionOverlay(
                background: AppPalette.transparent),
            onSelectedItemChanged: onChanged,
            children: [
              for (final v in values)
                Center(
                  child: Text(
                    v.toStringAsFixed(1),
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
