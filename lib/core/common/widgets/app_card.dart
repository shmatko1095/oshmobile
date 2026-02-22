import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';

class AppSolidCard extends StatelessWidget {
  const AppSolidCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.radius = AppPalette.radiusXl,
    this.backgroundColor = AppPalette.surface,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double radius;
  final Color backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final content = Ink(
      padding: padding ?? const EdgeInsets.all(AppPalette.spaceLg),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: child,
    );

    if (onTap == null) {
      return Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Colors.transparent,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        child: content,
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(radius),
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Colors.transparent,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        child: content,
      ),
    );
  }
}

class AppGlassCard extends StatelessWidget {
  const AppGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.radius = AppPalette.radiusXl,
    this.backgroundColor = AppPalette.surfaceRaised,
    this.borderColor = Colors.transparent,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double radius;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return AppSolidCard(
      padding: padding,
      onTap: onTap,
      radius: radius,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      child: child,
    );
  }
}
