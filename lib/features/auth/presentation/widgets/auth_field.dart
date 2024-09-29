import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';

class AuthField extends StatefulWidget {
  final String hintText;
  final String? labelText;
  final String? errorText;
  final IconData obscureIcon;
  final bool isObscureText;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;

  const AuthField({
    super.key,
    required this.hintText,
    this.labelText,
    this.errorText,
    this.validator,
    this.isObscureText = false,
    this.obscureIcon = Icons.remove_red_eye,
    required this.controller,
  });

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  late bool _isObscure;

  @override
  void initState() {
    super.initState();
    _isObscure = widget.isObscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      decoration: InputDecoration(
        hintText: widget.hintText,
        labelText: widget.labelText,
        errorText: widget.errorText,
        suffixIcon: widget.isObscureText
            ? IconButton(
                onPressed: () => setState(() {
                  _isObscure = !_isObscure;
                }),
                icon: Icon(
                  widget.obscureIcon,
                  color: _isObscure
                      ? AppPalette.obscureIconColor
                      : AppPalette.nonObscureIconColor,
                ),
              )
            : null,
      ),
      obscureText: _isObscure,
    );
  }
}
