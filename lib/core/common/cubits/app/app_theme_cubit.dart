import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/theme/theme_mode_storage.dart';

class AppThemeCubit extends Cubit<ThemeMode> {
  AppThemeCubit({required ThemeModeStorage storage})
      : _storage = storage,
        super(storage.readThemeMode());

  final ThemeModeStorage _storage;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (state == mode) return;
    emit(mode);
    await _storage.writeThemeMode(mode);
  }
}
