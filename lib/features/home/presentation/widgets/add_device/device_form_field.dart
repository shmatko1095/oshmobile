import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/core/utils/form_validators.dart';
import 'package:oshmobile/generated/l10n.dart';

class DeviceFormField extends StatelessWidget {
  final String? _hintText;
  final String? _labelText;
  final String? _errorText;
  final TextEditingController _controller;

  const DeviceFormField({
    super.key,
    String? hintText,
    String? labelText,
    String? errorText,
    required TextEditingController controller,
  })  : _errorText = errorText,
        _labelText = labelText,
        _hintText = hintText,
        _controller = controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      validator: (value) => FormValidator.length(
        value: value,
        errorMessage: S.of(context).InvalidValue,
      ),
      decoration: InputDecoration(
        focusColor: AppPalette.greyColor,
        hintText: _hintText,
        labelText: _labelText,
        errorText: _errorText,
      ),
    );
  }
}
