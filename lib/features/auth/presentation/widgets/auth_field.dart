import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';

class AuthField extends StatefulWidget {
  final String? hintText;
  final String? labelText;
  final String? errorText;
  final IconData obscureIcon;
  final bool isObscureText;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final bool enableContextMenu;

  const AuthField({
    super.key,
    this.hintText,
    this.labelText,
    this.errorText,
    this.validator,
    this.isObscureText = false,
    this.obscureIcon = Icons.remove_red_eye,
    this.enableContextMenu = false,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inactiveIconColor =
        isDark ? AppPalette.obscureIconColor : AppPalette.lightTextSubtle;

    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      enableInteractiveSelection: widget.enableContextMenu,
      contextMenuBuilder: widget.enableContextMenu
          ? null
          : (context, editableTextState) => const SizedBox.shrink(),
      cursorColor: theme.colorScheme.primary,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
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
                      ? inactiveIconColor
                      : theme.colorScheme.primary,
                ),
              )
            : null,
      ),
      obscureText: _isObscure,
    );
  }
}
