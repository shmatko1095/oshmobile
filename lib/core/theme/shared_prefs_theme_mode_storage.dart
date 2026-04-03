import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/theme_mode_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsThemeModeStorage implements ThemeModeStorage {
  SharedPrefsThemeModeStorage(this._prefs);

  static const _key = 'app_theme_mode';
  final SharedPreferences _prefs;

  @override
  ThemeMode readThemeMode() {
    final raw = _prefs.getString(_key);
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  @override
  Future<void> writeThemeMode(ThemeMode mode) {
    return _prefs.setString(_key, _encode(mode));
  }

  String _encode(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
  }
}
