import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';

class AppTheme {
  static OutlineInputBorder _border([Color color = AppPalette.borderColor]) => OutlineInputBorder(
        borderSide: BorderSide(
          color: color,
          width: 1.3,
        ),
        borderRadius: BorderRadius.circular(15),
      );

  static ThemeData get lightTheme => lightThemeMode;

  static final lightThemeMode = ThemeData.light().copyWith(
    scaffoldBackgroundColor: AppPalette.backgroundColorLight,
    appBarTheme: const AppBarTheme(
      surfaceTintColor: AppPalette.backgroundColorLight,
      backgroundColor: AppPalette.backgroundColorLight,
    ),
    chipTheme: const ChipThemeData(
      color: WidgetStatePropertyAll(AppPalette.backgroundColorLight),
      side: BorderSide.none,
    ),
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.all(25),
      floatingLabelStyle: TextStyle(color: AppPalette.blue),
      enabledBorder: _border(AppPalette.greyColor),
      focusedBorder: _border(AppPalette.blue),
      errorBorder: _border(AppPalette.errorColor),
      border: _border(),
    ),
  );

  static ThemeData get darkTheme => darkThemeMode;

  static final darkThemeMode = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: AppPalette.backgroundColorDark,
    appBarTheme: const AppBarTheme(
      surfaceTintColor: AppPalette.backgroundColorDark,
      backgroundColor: AppPalette.backgroundColorDark,
    ),
    chipTheme: const ChipThemeData(
      color: WidgetStatePropertyAll(AppPalette.backgroundColorDark),
      side: BorderSide.none,
    ),
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.all(25),
      floatingLabelStyle: TextStyle(color: AppPalette.blue),
      enabledBorder: _border(AppPalette.greyColor),
      focusedBorder: _border(AppPalette.blue),
      errorBorder: _border(AppPalette.errorColor),
      border: _border(),
    ),
  );
}
