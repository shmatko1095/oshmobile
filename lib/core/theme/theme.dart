import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/core/theme/component_themes.dart';

class AppTheme {
  static ThemeData get lightTheme => lightThemeMode;

  static const _lightColorScheme = ColorScheme.light(
    primary: AppPalette.accentPrimary,
    secondary: AppPalette.accentPrimary,
    surface: AppPalette.white,
    error: AppPalette.accentError,
    onPrimary: AppPalette.white,
    onSurface: AppPalette.lightTextBody,
  );

  static final lightThemeMode = ThemeData.light().copyWith(
    colorScheme: _lightColorScheme,
    scaffoldBackgroundColor: AppPalette.backgroundColorLight,
    canvasColor: AppPalette.backgroundColorLight,
    appBarTheme: const AppBarTheme(
      surfaceTintColor: AppPalette.backgroundColorLight,
      backgroundColor: AppPalette.backgroundColorLight,
      foregroundColor: AppPalette.lightTextPrimary,
      elevation: 0,
    ),
    chipTheme: const ChipThemeData(
      color: WidgetStatePropertyAll(AppPalette.backgroundColorLight),
      side: BorderSide.none,
    ),
    textTheme: ThemeData.light()
        .textTheme
        .apply(
          bodyColor: AppPalette.lightTextPrimary,
          displayColor: AppPalette.lightTextPrimary,
        )
        .copyWith(
          titleLarge:
              const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          titleMedium:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          titleSmall:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          bodyLarge:
              const TextStyle(fontSize: 16, color: AppPalette.lightTextPrimary),
          bodyMedium:
              const TextStyle(fontSize: 14, color: AppPalette.lightTextPrimary),
          bodySmall: const TextStyle(
              fontSize: 12, color: AppPalette.lightTextSecondary),
          labelLarge:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
    dividerColor: AppPalette.lightBorder,
    dividerTheme: const DividerThemeData(
      color: AppPalette.lightBorder,
      thickness: 0.8,
      space: 1,
    ),
    inputDecorationTheme: AppComponentThemes.lightInputDecoration,
    cardTheme: AppComponentThemes.lightCardTheme,
    elevatedButtonTheme: AppComponentThemes.lightElevatedButtonTheme,
    outlinedButtonTheme: AppComponentThemes.lightOutlinedButtonTheme,
    textButtonTheme: AppComponentThemes.lightTextButtonTheme,
    listTileTheme: AppComponentThemes.lightListTileTheme,
    drawerTheme: const DrawerThemeData(
      backgroundColor: AppPalette.backgroundColorLight,
      surfaceTintColor: AppPalette.backgroundColorLight,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return AppPalette.lightControlDisabled;
        }
        if (states.contains(WidgetState.selected)) {
          return AppPalette.white;
        }
        return AppPalette.lightControlThumb;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return AppPalette.lightControlTrack;
        }
        if (states.contains(WidgetState.selected)) {
          return AppPalette.accentPrimary;
        }
        return AppPalette.lightControlDisabled;
      }),
      trackOutlineColor: const WidgetStatePropertyAll(AppPalette.transparent),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: AppPalette.accentPrimary,
      inactiveTrackColor: AppPalette.lightControlTrack,
      thumbColor: AppPalette.white,
      overlayColor: AppPalette.accentPrimary.withValues(alpha: 0.18),
      valueIndicatorColor: AppPalette.white,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppPalette.white,
      contentTextStyle: TextStyle(color: AppPalette.lightTextPrimary),
    ),
  );

  static ThemeData get darkTheme => darkThemeMode;

  static const _darkColorScheme = ColorScheme.dark(
    primary: AppPalette.accentPrimary,
    secondary: AppPalette.accentPrimary,
    surface: AppPalette.surface,
    error: AppPalette.accentError,
    onPrimary: AppPalette.white,
    onSurface: AppPalette.textPrimary,
  );

  static final darkThemeMode = ThemeData.dark().copyWith(
    colorScheme: _darkColorScheme,
    scaffoldBackgroundColor: AppPalette.canvas,
    canvasColor: AppPalette.canvas,
    appBarTheme: const AppBarTheme(
      surfaceTintColor: AppPalette.canvas,
      backgroundColor: AppPalette.canvas,
      foregroundColor: AppPalette.textPrimary,
      elevation: 0,
    ),
    chipTheme: const ChipThemeData(
      color: WidgetStatePropertyAll(AppPalette.surfaceRaised),
      side: BorderSide.none,
    ),
    textTheme: ThemeData.dark()
        .textTheme
        .apply(
          bodyColor: AppPalette.textPrimary,
          displayColor: AppPalette.textPrimary,
        )
        .copyWith(
          titleLarge:
              const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          titleMedium:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          titleSmall:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          bodyLarge:
              const TextStyle(fontSize: 16, color: AppPalette.textPrimary),
          bodyMedium:
              const TextStyle(fontSize: 14, color: AppPalette.textPrimary),
          bodySmall:
              const TextStyle(fontSize: 12, color: AppPalette.textSecondary),
          labelLarge:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
    inputDecorationTheme: AppComponentThemes.darkInputDecoration,
    dividerColor: AppPalette.separator,
    dividerTheme: const DividerThemeData(
      color: AppPalette.separator,
      thickness: 0.8,
      space: 1,
    ),
    cardTheme: AppComponentThemes.darkCardTheme,
    elevatedButtonTheme: AppComponentThemes.darkElevatedButtonTheme,
    outlinedButtonTheme: AppComponentThemes.darkOutlinedButtonTheme,
    textButtonTheme: AppComponentThemes.darkTextButtonTheme,
    listTileTheme: AppComponentThemes.darkListTileTheme,
    drawerTheme: const DrawerThemeData(
      backgroundColor: AppPalette.canvas,
      surfaceTintColor: AppPalette.canvas,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppPalette.surfaceRaised,
      foregroundColor: AppPalette.textPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppPalette.radiusLg),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return AppPalette.textMuted.withValues(alpha: 0.7);
        }
        if (states.contains(WidgetState.selected)) {
          return AppPalette.white;
        }
        return AppPalette.darkControlThumb;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return AppPalette.textMuted.withValues(alpha: 0.25);
        }
        if (states.contains(WidgetState.selected)) {
          return AppPalette.accentPrimary;
        }
        return AppPalette.darkControlTrack;
      }),
      trackOutlineColor: const WidgetStatePropertyAll(AppPalette.transparent),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: AppPalette.accentPrimary,
      inactiveTrackColor: AppPalette.white24,
      thumbColor: AppPalette.white,
      overlayColor: AppPalette.accentPrimary.withValues(alpha: 0.18),
      valueIndicatorColor: AppPalette.surfaceRaised,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppPalette.surfaceRaised,
      contentTextStyle: TextStyle(color: AppPalette.textPrimary),
    ),
  );
}
