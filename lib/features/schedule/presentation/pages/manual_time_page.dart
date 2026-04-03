import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/auth/presentation/widgets/elevated_button.dart';
import 'package:oshmobile/generated/l10n.dart';

bool _manualTimeIsDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color _manualTimePrimaryTextColor(BuildContext context) =>
    _manualTimeIsDark(context)
        ? AppPalette.textPrimary
        : AppPalette.lightTextPrimary;

Color _manualTimeSecondaryTextColor(BuildContext context) =>
    _manualTimeIsDark(context)
        ? AppPalette.textSecondary
        : AppPalette.lightTextSecondary;

class ManualTimePage extends StatefulWidget {
  const ManualTimePage({
    super.key,
    required this.title,
    required this.initial,
    required this.onSave,
    this.minuteInterval = 1,
  })  : assert(minuteInterval > 0 && minuteInterval <= 30),
        assert(60 % minuteInterval == 0);

  final String title;
  final TimeOfDay initial;
  final ValueChanged<TimeOfDay> onSave;
  final int minuteInterval;

  @override
  State<ManualTimePage> createState() => _ManualTimePageState();
}

class _ManualTimePageState extends State<ManualTimePage> {
  late final List<int> _hours;
  late final List<int> _minutes;
  late int _hourIndex;
  late int _minuteIndex;

  @override
  void initState() {
    super.initState();
    _hours = List<int>.generate(24, (i) => i);
    _minutes = [
      for (var m = 0; m < 60; m += widget.minuteInterval) m,
    ];
    _hourIndex = widget.initial.hour.clamp(0, _hours.length - 1);
    _minuteIndex = _closestMinuteIndex(widget.initial.minute);
  }

  int _closestMinuteIndex(int minute) {
    var best = 0;
    var bestDistance = 1 << 30;
    for (var i = 0; i < _minutes.length; i++) {
      final d = (_minutes[i] - minute).abs();
      if (d < bestDistance) {
        bestDistance = d;
        best = i;
      }
    }
    return best;
  }

  TimeOfDay get _selected =>
      TimeOfDay(hour: _hours[_hourIndex], minute: _minutes[_minuteIndex]);

  String _fmt2(int n) => n.toString().padLeft(2, '0');

  String _fmtTime(TimeOfDay t) => '${_fmt2(t.hour)}:${_fmt2(t.minute)}';

  void _onSave(BuildContext context) {
    widget.onSave(_selected);
    Navigator.of(context).pop();
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
                color: _manualTimePrimaryTextColor(context),
              ),
              child: Text(_fmtTime(_selected)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _PickerColumn(
                      values: _hours,
                      initialIndex: _hourIndex,
                      onChanged: (i) => setState(() => _hourIndex = i),
                      textColor: _manualTimePrimaryTextColor(context),
                    ),
                  ),
                  Text(
                    ':',
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      color: _manualTimeSecondaryTextColor(context),
                    ),
                  ),
                  Expanded(
                    child: _PickerColumn(
                      values: _minutes,
                      initialIndex: _minuteIndex,
                      onChanged: (i) => setState(() => _minuteIndex = i),
                      textColor: _manualTimePrimaryTextColor(context),
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
    required this.values,
    required this.initialIndex,
    required this.onChanged,
    required this.textColor,
  });

  final List<int> values;
  final int initialIndex;
  final ValueChanged<int> onChanged;
  final Color textColor;

  String _fmt2(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return CupertinoPicker(
      itemExtent: 68,
      diameterRatio: 1.5,
      magnification: 1.1,
      scrollController: FixedExtentScrollController(initialItem: initialIndex),
      selectionOverlay: const CupertinoPickerDefaultSelectionOverlay(
        background: AppPalette.transparent,
      ),
      onSelectedItemChanged: onChanged,
      children: [
        for (final v in values)
          Center(
            child: Text(
              _fmt2(v),
              style: TextStyle(
                color: textColor,
                fontSize: 36,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
