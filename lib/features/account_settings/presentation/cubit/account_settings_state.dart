import 'package:flutter/foundation.dart';
import 'package:oshmobile/features/account_settings/domain/models/app_theme_preference.dart';

@immutable
class AccountSettingsState {
  final AppThemePreference selectedTheme;
  final bool isDeleting;

  const AccountSettingsState({
    this.selectedTheme = AppThemePreference.system,
    this.isDeleting = false,
  });

  AccountSettingsState copyWith({
    AppThemePreference? selectedTheme,
    bool? isDeleting,
  }) {
    return AccountSettingsState(
      selectedTheme: selectedTheme ?? this.selectedTheme,
      isDeleting: isDeleting ?? this.isDeleting,
    );
  }
}
