import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';

class CustomElevatedButton extends StatelessWidget {
  final BorderRadiusGeometry? borderRadius;
  final Widget? icon;
  final double? width;
  final double? height;
  final VoidCallback? onPressed;
  final String buttonText;
  final Color backgroundColor;

  const CustomElevatedButton({
    super.key,
    this.backgroundColor = AppPalette.gradient3,
    required this.onPressed,
    required this.buttonText,
    this.borderRadius,
    this.width = double.maxFinite,
    this.height = 50,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: borderRadius ?? BorderRadius.circular(13)),
        ),
        icon: icon,
        label: Text(
          buttonText,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
