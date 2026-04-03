import 'package:flutter/material.dart';

abstract interface class ThemeModeStorage {
  ThemeMode readThemeMode();
  Future<void> writeThemeMode(ThemeMode mode);
}
