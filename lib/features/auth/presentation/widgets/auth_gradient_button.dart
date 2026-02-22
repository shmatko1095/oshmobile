import 'package:flutter/material.dart';
import 'package:oshmobile/core/common/widgets/app_button.dart';

class AuthGradientButton extends StatelessWidget {
  final String buttonText;
  final VoidCallback onPressed;

  const AuthGradientButton({
    super.key,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton(
      text: buttonText,
      onPressed: onPressed,
    );
  }
}
