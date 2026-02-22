import 'package:flutter/material.dart';

class AppPalette {
  // Semantic dark-first design tokens (Samsung One UI inspired)
  static const Color canvas = Color(0xFF000000);
  static const Color surface = Color(0xFF181818);
  static const Color surfaceRaised = Color(0xFF1B1B1B);
  static const Color surfaceAlt = Color(0xFF242424);
  static const Color glass = Color(0xFF1B1B1B);
  static const Color borderSoft = Color(0x12FFFFFF); // ~7% white
  static const Color borderGlass = Color(0x14FFFFFF); // ~8% white
  static const Color separator = Color(0x18FFFFFF); // ~9% white

  static const Color textPrimary = Color(0xFFF5F7FA);
  static const Color textSecondary = Color(0xFFB8BDCC);
  static const Color textMuted = Color(0xFF8D94A5);

  static const Color accentPrimary = Color(0xFF3779FC);
  static const Color accentSuccess = Color(0xFF34C759);
  static const Color accentWarning = Color(0xFFFF5252);
  static const Color accentError = Color(0xFFEF4444);

  static const Color destructiveBg = Color(0x1FEF4444);
  static const Color destructiveFg = Color(0xFFF87171);

  // Base backgrounds
  static const Color backgroundColorLight = Color(0xffF1F1F1);
  static const Color backgroundColorDark = canvas;
  static const Color activeTextFieldColorLight = Color(0xffe7e7e7);
  static const Color activeTextFieldColorDark = surfaceRaised;

  static const Color obscureIconColor = textMuted;
  static const Color nonObscureIconColor = accentPrimary;

  // Radius tokens
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 24;
  static const double radiusXl = 28;
  static const double radiusPill = 999;

  // Spacing tokens
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 24;
  static const double space2xl = 32;

  // Motion tokens
  static const Duration motionFast = Duration(milliseconds: 120);
  static const Duration motionBase = Duration(milliseconds: 180);
  static const Duration motionSlow = Duration(milliseconds: 240);
}
