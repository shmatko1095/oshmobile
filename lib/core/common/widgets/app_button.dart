import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final double? width;
  final double? height;
  final bool isLoading;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.width,
    this.height,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = backgroundColor ?? AppPalette.gradient3;

    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: activeColor,
          disabledBackgroundColor: isLoading ? activeColor : Colors.grey[300],
          foregroundColor: Colors.white,
          disabledForegroundColor: isLoading ? Colors.white : Colors.grey[600],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          padding: EdgeInsets.zero,
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
