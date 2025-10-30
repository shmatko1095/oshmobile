import 'package:flutter/cupertino.dart';

class DarkCupertinoTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? placeholder;
  final TextInputType? keyboardType;
  final bool obscureText;

  const DarkCupertinoTextField({
    super.key,
    this.controller,
    this.placeholder,
    this.keyboardType,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      keyboardType: keyboardType,
      obscureText: obscureText,
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      style: TextStyle(
        color: CupertinoDynamicColor.resolve(
          CupertinoColors.label,
          context,
        ),
      ),
      decoration: BoxDecoration(
        color: CupertinoDynamicColor.resolve(
          CupertinoColors.systemGrey6,
          context,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
