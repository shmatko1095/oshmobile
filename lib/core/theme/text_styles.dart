import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';

class TextStyles {
  static const titleStyle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    height: 1.15,
  );

  static const TextStyle contentStyle = TextStyle(
    fontSize: 16,
    color: AppPalette.textSecondary,
    height: 1.4,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppPalette.textPrimary,
    height: 1.3,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppPalette.textPrimary,
    height: 1.4,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppPalette.textPrimary,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppPalette.textSecondary,
    height: 1.35,
  );
}
