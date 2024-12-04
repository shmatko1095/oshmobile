import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';

class AppTheme {
  static _border([Color color = AppPalette.borderColor]) => OutlineInputBorder(
        borderSide: BorderSide(
          color: color,
          width: 1.1,
        ),
        borderRadius: BorderRadius.circular(15),
      );

  static get lightTheme => ThemeData.light().copyWith(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent));

  static get darkTheme => darkThemeMode;

  static final darkThemeMode = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: AppPalette.backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppPalette.backgroundColor,
    ),
    chipTheme: const ChipThemeData(
      color: WidgetStatePropertyAll(AppPalette.backgroundColor),
      side: BorderSide.none,
    ),
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.all(27),
      enabledBorder: _border(),
      focusedBorder: _border(AppPalette.blue),
      errorBorder: _border(AppPalette.errorColor),
      border: _border(),
    ),
  );
}
