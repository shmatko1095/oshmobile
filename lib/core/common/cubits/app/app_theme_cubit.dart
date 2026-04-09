import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/analytics/osh_analytics.dart';
import 'package:oshmobile/core/analytics/osh_analytics_user_properties.dart';
import 'package:oshmobile/core/theme/theme_mode_storage.dart';

class AppThemeCubit extends Cubit<ThemeMode> {
  AppThemeCubit({required ThemeModeStorage storage})
      : _storage = storage,
        super(storage.readThemeMode()) {
    unawaited(_syncAnalyticsProperty(state));
  }

  final ThemeModeStorage _storage;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (state == mode) return;
    emit(mode);
    await _syncAnalyticsProperty(mode);
    await _storage.writeThemeMode(mode);
  }

  Future<void> _syncAnalyticsProperty(ThemeMode mode) {
    return OshAnalytics.setUserProperty(
      name: OshAnalyticsUserProperties.appTheme,
      value: switch (mode) {
        ThemeMode.system => 'system',
        ThemeMode.dark => 'dark',
        ThemeMode.light => 'light',
      },
    );
  }
}
