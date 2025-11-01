import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:oshmobile/features/auth/presentation/widgets/elevated_button.dart';
import 'package:oshmobile/generated/l10n.dart';

class ManualTemperaturePage extends StatefulWidget {
  const ManualTemperaturePage({
    super.key,
    required this.initial,
    required this.onSave,
    required this.title,
    this.min = 5.0,
    this.max = 35.0,
    this.step = 0.5,
    this.unit = '°C',
  });

  final double initial;
  final void Function(double value) onSave;

  final double min, max, step;
  final String title, unit;

  @override
  State<ManualTemperaturePage> createState() => _ManualTemperaturePageState();
}

class _ManualTemperaturePageState extends State<ManualTemperaturePage> {
  late final List<double> _values;
  late int _index;

  @override
  void initState() {
    super.initState();
    _values = [
      for (double v = widget.min; v <= widget.max + 1e-6; v += widget.step) double.parse(v.toStringAsFixed(1)),
    ];
    _index = _closestIndex(widget.initial);
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

  void _onSave(BuildContext context) {
    final value = _values[_index];
    widget.onSave(value);
    Navigator.pop(context);
  }

  String _fmt(double v) => v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        // elevation: 0,
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 160),
              style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w600, color: Colors.white),
              child: Text('${_fmt(_values[_index])}${widget.unit}'),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 68,
                diameterRatio: 1.5,
                magnification: 1.1,
                scrollController: FixedExtentScrollController(initialItem: _index),
                selectionOverlay: const CupertinoPickerDefaultSelectionOverlay(background: Colors.transparent),
                onSelectedItemChanged: (i) => setState(() => _index = i),
                children: [
                  for (final v in _values)
                    Center(
                      child: Text(
                        _fmt(v),
                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w600),
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
