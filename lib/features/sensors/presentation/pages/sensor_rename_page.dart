import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/features/sensors/presentation/utils/sensors_patch_schema_validator.dart';
import 'package:oshmobile/generated/l10n.dart';

class SensorRenamePage extends StatefulWidget {
  final String sensorId;
  final String initialName;

  const SensorRenamePage({
    super.key,
    required this.sensorId,
    required this.initialName,
  });

  @override
  State<SensorRenamePage> createState() => _SensorRenamePageState();
}

class _SensorRenamePageState extends State<SensorRenamePage> {
  final TextEditingController _nameCtrl = TextEditingController();

  late final String _initialNormalizedName;
  late final SensorsPatchSchemaValidator _schemaValidator;
  late final SensorRenameConstraints? _constraints;

  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final facade = context.read<DeviceFacade>();
    _schemaValidator = SensorsPatchSchemaValidator.fromSnapshot(facade.current);
    _constraints = _schemaValidator.renameConstraints;
    _initialNormalizedName = _normalize(widget.initialName);
    _nameCtrl.text = widget.initialName;
    _nameCtrl.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_onNameChanged);
    _nameCtrl.dispose();
    super.dispose();
  }

  String _normalize(String value) => value.trim();

  String get _normalizedName => _normalize(_nameCtrl.text);

  bool get _hasChanges => _normalizedName != _initialNormalizedName;

  bool get _isLocallyValid => _schemaValidator.validateRename(
        id: widget.sensorId,
        name: _normalizedName,
      );

  bool get _canSave => !_isSaving && _hasChanges && _isLocallyValid;

  void _onNameChanged() {
    if (!mounted) return;

    setState(() {
      _errorText =
          _isLocallyValid || !_hasChanges ? null : S.of(context).InvalidValue;
    });
  }

  Future<void> _save() async {
    if (!_canSave) return;
    if (!_isLocallyValid) {
      setState(() => _errorText = S.of(context).InvalidValue);
      return;
    }

    final facade = context.read<DeviceFacade>();

    setState(() => _isSaving = true);

    try {
      await facade.sensors.rename(
        id: widget.sensorId,
        name: _normalizedName,
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

  @override
  Widget build(BuildContext context) {
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
          title: Text(S.of(context).SensorRename),
          actions: [
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
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
              TextFormField(
                controller: _nameCtrl,
                maxLength: _constraints?.maxLength,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) {
                  if (_canSave) {
                    _save();
                  }
                },
                decoration: InputDecoration(
                  labelText: S.of(context).Name,
                  hintText: S.of(context).SensorNameHint,
                  errorText: _errorText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _DiscardDialogResult { discard, cancel }
