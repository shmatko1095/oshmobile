import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/features/sensors/presentation/utils/sensors_patch_schema_validator.dart';
import 'package:oshmobile/generated/l10n.dart';

bool _sensorCalibrationIsDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color _sensorCalibrationPrimaryTextColor(BuildContext context) =>
    _sensorCalibrationIsDark(context)
        ? AppPalette.textPrimary
        : const Color(0xFF0F172A);

Color _sensorCalibrationSecondaryTextColor(BuildContext context) =>
    _sensorCalibrationIsDark(context)
        ? AppPalette.textSecondary
        : const Color(0xFF475569);

class SensorCalibrationPage extends StatefulWidget {
  final String sensorId;
  final double initialCalibration;

  const SensorCalibrationPage({
    super.key,
    required this.sensorId,
    required this.initialCalibration,
  });

  @override
  State<SensorCalibrationPage> createState() => _SensorCalibrationPageState();
}

class _SensorCalibrationPageState extends State<SensorCalibrationPage> {
  static const String _missingLimitsMessage =
      'Calibration limits are not defined in MQTT schema.';

  late final SensorsPatchSchemaValidator _schemaValidator;
  late final SensorCalibrationConstraints? _constraints;

  late final double _initialValue;
  late double _currentValue;

  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final facade = context.read<DeviceFacade>();
    _schemaValidator = SensorsPatchSchemaValidator.fromSnapshot(
      facade.current,
    );
    _constraints = _schemaValidator.tempCalibrationConstraints;

    _initialValue = _snap(widget.initialCalibration);
    _currentValue = _initialValue;
  }

  bool get _hasCalibrationConstraints => _constraints?.isUsable ?? false;

  int? get _divisions => _constraints?.divisions;

  bool get _hasChanges => (_currentValue - _initialValue).abs() > 1e-9;

  bool get _canSave => _hasCalibrationConstraints && !_isSaving && _hasChanges;

  double _snap(double value) {
    final constraints = _constraints;
    if (constraints == null || !constraints.isUsable) {
      return value;
    }
    return constraints.snap(value);
  }

  String _fmt(double value) {
    if (value % 1 == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  bool _isValidValue() {
    return _schemaValidator.validateTempCalibration(
      id: widget.sensorId,
      value: _currentValue,
    );
  }

  Future<void> _save() async {
    if (!_canSave) return;
    if (!_hasCalibrationConstraints) {
      setState(() => _errorText = _missingLimitsMessage);
      return;
    }

    if (!_isValidValue()) {
      setState(() => _errorText = S.of(context).InvalidValue);
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      final facade = context.read<DeviceFacade>();
      await facade.sensors.setTempCalibration(
        id: widget.sensorId,
        value: _currentValue,
      );
      await facade.refreshAll(forceGet: true);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      SnackBarUtils.showFail(
        context: context,
        content: error.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!_hasChanges || _isSaving) {
      return true;
    }

    final result = await showDialog<_DiscardDialogResult>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(S.of(context).UnsavedChanges),
          content: Text(S.of(context).UnsavedChangesDiscardPrompt),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(_DiscardDialogResult.cancel),
              child: Text(S.of(context).Cancel),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(_DiscardDialogResult.discard),
              child: Text(S.of(context).Discard),
            ),
          ],
        );
      },
    );

    return result == _DiscardDialogResult.discard;
  }

  Future<void> _onBackPressed() async {
    final shouldPop = await _confirmDiscard();
    if (shouldPop && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _onSliderChanged(double value) {
    if (_isSaving) return;
    setState(() {
      _currentValue = _snap(value);
      _errorText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final constraints = _constraints;
    final canSave = _canSave;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _onBackPressed();
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          leading: BackButton(onPressed: _onBackPressed),
          title: Text(S.of(context).SensorCalibration),
          actions: [
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CupertinoActivityIndicator(),
                  ),
                ),
              )
            else
              TextButton(
                onPressed: canSave ? _save : null,
                child: Text(
                  S.of(context).Save,
                  style: TextStyle(
                    color: canSave
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).disabledColor,
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppPalette.spaceLg,
              AppPalette.spaceLg,
              AppPalette.spaceLg,
              AppPalette.spaceXl,
            ),
            children: [
              Text(
                S.of(context).SensorCalibration,
                style: TextStyle(
                  color: _sensorCalibrationSecondaryTextColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_fmt(_currentValue)} °C',
                style: TextStyle(
                  color: _sensorCalibrationPrimaryTextColor(context),
                  fontSize: 40,
                  fontWeight: FontWeight.w300,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 20),
              if (constraints != null && constraints.isUsable) ...[
                Slider(
                  value: _currentValue,
                  min: constraints.min,
                  max: constraints.max,
                  divisions: _divisions,
                  label: '${_fmt(_currentValue)} °C',
                  onChanged: _isSaving ? null : _onSliderChanged,
                ),
                Row(
                  children: [
                    Text(
                      '${_fmt(constraints.min)} °C',
                      style: TextStyle(
                        color: _sensorCalibrationSecondaryTextColor(context),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_fmt(constraints.max)} °C',
                      style: TextStyle(
                        color: _sensorCalibrationSecondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              ] else
                Text(
                  _missingLimitsMessage,
                  style: TextStyle(
                    color: _sensorCalibrationSecondaryTextColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (_errorText != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorText!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _DiscardDialogResult { discard, cancel }
