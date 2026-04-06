import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';

class AppComponentThemes {
  static OutlineInputBorder border([Color color = AppPalette.borderSoft]) =>
      OutlineInputBorder(
        borderSide: BorderSide(
          color: color,
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(AppPalette.radiusMd),
      );

  static InputDecorationTheme get lightInputDecoration => InputDecorationTheme(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: AppPalette.white,
        hintStyle: const TextStyle(color: AppPalette.lightTextSubtle),
        labelStyle: const TextStyle(color: AppPalette.lightTextSecondary),
        floatingLabelStyle: const TextStyle(
          color: AppPalette.accentPrimary,
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: border(AppPalette.lightBorderStrong),
        disabledBorder: border(AppPalette.lightBorderSubtle),
        focusedBorder: border(AppPalette.accentPrimary),
        errorBorder: border(AppPalette.accentError),
        focusedErrorBorder: border(AppPalette.accentError),
        border: border(AppPalette.lightBorderStrong),
      );

  static InputDecorationTheme get darkInputDecoration => InputDecorationTheme(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        floatingLabelStyle: const TextStyle(color: AppPalette.accentPrimary),
        filled: true,
        fillColor: AppPalette.surfaceRaised,
        enabledBorder: border(AppPalette.borderSoft),
        focusedBorder: border(AppPalette.accentPrimary),
        errorBorder: border(AppPalette.accentError),
        focusedErrorBorder: border(AppPalette.accentError),
        border: border(),
      );

  static CardThemeData get lightCardTheme => CardThemeData(
        color: AppPalette.white,
        margin: EdgeInsets.zero,
        elevation: 0,
        surfaceTintColor: AppPalette.transparent,
        shadowColor: AppPalette.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppPalette.radiusLg),
        ),
      );

  static CardThemeData get darkCardTheme => CardThemeData(
        color: AppPalette.surface,
        margin: EdgeInsets.zero,
        elevation: 0,
        surfaceTintColor: AppPalette.transparent,
        shadowColor: AppPalette.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppPalette.radiusXl),
        ),
      );

  static ElevatedButtonThemeData get lightElevatedButtonTheme =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.accentPrimary,
          foregroundColor: AppPalette.white,
          disabledBackgroundColor: AppPalette.lightSurfaceMuted,
          disabledForegroundColor: AppPalette.lightTextDisabled,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppPalette.radiusMd),
          ),
        ),
      );

  static ElevatedButtonThemeData get darkElevatedButtonTheme =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.accentPrimary,
          foregroundColor: AppPalette.white,
          disabledBackgroundColor: AppPalette.surfaceAlt,
          disabledForegroundColor: AppPalette.textMuted,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppPalette.radiusMd),
          ),
        ),
      );

  static OutlinedButtonThemeData get lightOutlinedButtonTheme =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.lightTextPrimary,
          side: const BorderSide(color: AppPalette.lightBorderSubtle),
          minimumSize: const Size.fromHeight(50),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppPalette.radiusMd),
          ),
        ),
      );

  static OutlinedButtonThemeData get darkOutlinedButtonTheme =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.textPrimary,
          side: const BorderSide(color: AppPalette.borderSoft),
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppPalette.radiusMd),
          ),
        ),
      );

  static TextButtonThemeData get lightTextButtonTheme => TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppPalette.accentPrimary,
          disabledForegroundColor: AppPalette.lightTextDisabled,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppPalette.radiusSm),
          ),
        ),
      );

  static TextButtonThemeData get darkTextButtonTheme => TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppPalette.accentPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppPalette.radiusSm),
          ),
        ),
      );

  static const ListTileThemeData lightListTileTheme = ListTileThemeData(
    contentPadding: EdgeInsets.symmetric(horizontal: 16),
  );

  static const ListTileThemeData darkListTileTheme = ListTileThemeData(
    contentPadding: EdgeInsets.symmetric(horizontal: 16),
    iconColor: AppPalette.textSecondary,
    textColor: AppPalette.textPrimary,
    dense: false,
  );
}
