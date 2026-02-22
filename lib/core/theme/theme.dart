import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/core/theme/component_themes.dart';

class AppTheme {
  static ThemeData get lightTheme => lightThemeMode;

  static const _lightColorScheme = ColorScheme.light(
    primary: AppPalette.accentPrimary,
    secondary: AppPalette.accentPrimary,
    surface: Colors.white,
    error: AppPalette.accentError,
    onPrimary: Colors.white,
    onSurface: Color(0xFF1E293B),
  );

  static final lightThemeMode = ThemeData.light().copyWith(
    colorScheme: _lightColorScheme,
    scaffoldBackgroundColor: AppPalette.backgroundColorLight,
    appBarTheme: const AppBarTheme(
      surfaceTintColor: AppPalette.backgroundColorLight,
      backgroundColor: AppPalette.backgroundColorLight,
    ),
    chipTheme: const ChipThemeData(
      color: WidgetStatePropertyAll(AppPalette.backgroundColorLight),
      side: BorderSide.none,
    ),
    inputDecorationTheme: AppComponentThemes.lightInputDecoration,
    cardTheme: AppComponentThemes.lightCardTheme,
    elevatedButtonTheme: AppComponentThemes.lightElevatedButtonTheme,
    outlinedButtonTheme: AppComponentThemes.lightOutlinedButtonTheme,
    textButtonTheme: AppComponentThemes.lightTextButtonTheme,
    listTileTheme: AppComponentThemes.lightListTileTheme,
  );

  static ThemeData get darkTheme => darkThemeMode;

  static const _darkColorScheme = ColorScheme.dark(
    primary: AppPalette.accentPrimary,
    secondary: AppPalette.accentPrimary,
    surface: AppPalette.surface,
    error: AppPalette.accentError,
    onPrimary: Colors.white,
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
          return Colors.white;
        }
        return const Color(0xFFE3E5EC);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return AppPalette.textMuted.withValues(alpha: 0.25);
        }
        if (states.contains(WidgetState.selected)) {
          return AppPalette.accentPrimary;
        }
        return const Color(0xFF6A6C75);
      }),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: AppPalette.accentPrimary,
      inactiveTrackColor: Colors.white24,
      thumbColor: Colors.white,
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
