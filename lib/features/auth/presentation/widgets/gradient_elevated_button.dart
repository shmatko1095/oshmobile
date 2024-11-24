import 'package:flutter/material.dart';

class GradientElevatedButton extends StatelessWidget {
  final BorderRadiusGeometry? borderRadius;
  final double? width;
  final double? height;
  final Gradient gradient;
  final VoidCallback? onPressed;
  final String buttonText;

  const GradientElevatedButton({
    super.key,
    this.gradient = const LinearGradient(colors: [Colors.indigo, Colors.cyan]),
    required this.onPressed,
    required this.buttonText,
    this.borderRadius,
    this.width = double.maxFinite,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = this.borderRadius ?? BorderRadius.circular(30);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: borderRadius,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
        child: Text(
          buttonText,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
