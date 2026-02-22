import 'package:flutter/material.dart';
import 'package:oshmobile/core/common/widgets/app_button.dart';

class CustomElevatedButton extends StatelessWidget {
  final BorderRadius? borderRadius;
  final Widget? icon;
  final double? width;
  final double? height;
  final VoidCallback? onPressed;
  final String buttonText;
  final Color? backgroundColor;

  const CustomElevatedButton({
    super.key,
    this.backgroundColor,
    required this.onPressed,
    required this.buttonText,
    this.borderRadius,
    this.width = double.maxFinite,
    this.height = 50,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton(
      text: buttonText,
      onPressed: onPressed,
      width: width,
      height: height,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      icon: icon,
    );
  }
}
