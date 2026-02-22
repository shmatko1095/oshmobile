import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? icon;
  final bool isLoading;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height,
    this.borderRadius,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabledFgColor = Theme.of(context)
            .elevatedButtonTheme
            .style
            ?.foregroundColor
            ?.resolve({WidgetState.disabled}) ??
        Theme.of(context).disabledColor;

    final label = Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );

    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: _resolveOverrides(),
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CupertinoActivityIndicator(
                  color: disabledFgColor,
                ),
              )
            : (icon == null
                ? label
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      icon!,
                      const SizedBox(width: 10),
                      Flexible(child: label),
                    ],
                  )),
      ),
    );
  }

  ButtonStyle? _resolveOverrides() {
    final hasOverrides = backgroundColor != null ||
        foregroundColor != null ||
        borderRadius != null;
    if (!hasOverrides) return null;

    return ButtonStyle(
      backgroundColor: backgroundColor != null
          ? WidgetStatePropertyAll(backgroundColor)
          : null,
      foregroundColor: foregroundColor != null
          ? WidgetStatePropertyAll(foregroundColor)
          : null,
      shape: borderRadius != null
          ? WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: borderRadius!),
            )
          : null,
    );
  }
}
