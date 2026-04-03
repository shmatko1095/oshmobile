import 'package:flutter/material.dart';

class AppPalette {
  // Shared literal colors centralized to avoid screen-level hardcoding.
  static const Color transparent = Color(0x00000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color white24 = Color(0x3DFFFFFF);
  static const Color black54 = Color(0x8A000000);

  static const Color grey = Color(0xFF9E9E9E);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey700 = Color(0xFF616161);

  static const Color lightTextBody = Color(0xFF1E293B);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextStrong = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF4B5563);
  static const Color lightTextSubtle = Color(0xFF64748B);
  static const Color lightTextDisabled = Color(0xFF6B7280);

  static const Color lightBorder = Color(0x1A0F172A);
  static const Color lightBorderStrong = Color(0x2A0F172A);
  static const Color lightBorderSubtle = Color(0xFFE2E8F0);
  static const Color lightControlDisabled = Color(0xFF94A3B8);
  static const Color lightControlTrack = Color(0xFFCBD5E1);
  static const Color lightControlThumb = Color(0xFFE5E7EB);
  static const Color darkControlThumb = Color(0xFFE3E5EC);
  static const Color darkControlTrack = Color(0xFF6A6C75);

  static const Color lightSurfaceMuted = Color(0xFFF1F3F5);
  static const Color lightSurfaceSubtle = Color(0xFFF3F4F6);
  static const Color lightSurfaceSoft = Color(0xFFF8FAFC);

  static const Color tooltipDarkSurface = Color(0xFF141820);
  static const Color chartTempInactive = Color(0xFF7BC5FF);

  static const Color orangeAccent = Color(0xFFFFAB40);
  static const Color cyanAccent = Color(0xFF18FFFF);
  static const Color amber = Color(0xFFFFC107);
  static const Color amberAccent = Color(0xFFFFD740);
  static const Color green = Color(0xFF4CAF50);
  static const Color indigo = Color(0xFF3F51B5);
  static const Color cyan = Color(0xFF00BCD4);

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
