import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/cubits/app/app_theme_cubit.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';
import 'package:oshmobile/core/usecase/usecase.dart';
import 'package:oshmobile/features/account_settings/domain/models/app_theme_preference.dart';
import 'package:oshmobile/features/account_settings/domain/usecases/request_my_account_deletion.dart';
import 'package:oshmobile/features/account_settings/presentation/cubit/account_settings_state.dart';

class AccountSettingsCubit extends Cubit<AccountSettingsState> {
  AccountSettingsCubit({
    required AppThemeCubit appThemeCubit,
    required RequestMyAccountDeletion requestMyAccountDeletion,
  })  : _appThemeCubit = appThemeCubit,
        _requestMyAccountDeletion = requestMyAccountDeletion,
        super(AccountSettingsState(
          selectedTheme: _fromThemeMode(appThemeCubit.state),
        )) {
    _themeSub = _appThemeCubit.stream.listen((mode) {
      final mapped = _fromThemeMode(mode);
      if (mapped == state.selectedTheme) return;
      emit(state.copyWith(selectedTheme: mapped));
    });
  }

  final AppThemeCubit _appThemeCubit;
  final RequestMyAccountDeletion _requestMyAccountDeletion;
  late final StreamSubscription<ThemeMode> _themeSub;

  void changeTheme(AppThemePreference preference) {
    emit(state.copyWith(selectedTheme: preference));
    onThemeChanged(preference);
  }

  Future<void> deleteAccount() async {
    if (state.isDeleting) return;

    emit(state.copyWith(isDeleting: true));
    try {
      await onDeleteAccountConfirmed();
    } catch (error, st) {
      OshCrashReporter.logNonFatal(
        error,
        st,
        reason: 'Account deletion request failed',
      );
      rethrow;
    } finally {
      emit(state.copyWith(isDeleting: false));
    }
  }

  void onThemeChanged(AppThemePreference preference) {
    _appThemeCubit.setThemeMode(_toThemeMode(preference));
  }

  Future<void> onDeleteAccountConfirmed() async {
    final result = await _requestMyAccountDeletion(NoParams());
    result.fold(
      (failure) => throw StateError(
        failure.message ?? 'Account deletion request failed',
      ),
      (_) {},
    );
  }

  @override
  Future<void> close() async {
    await _themeSub.cancel();
    return super.close();
  }

  static AppThemePreference _fromThemeMode(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => AppThemePreference.system,
      ThemeMode.dark => AppThemePreference.dark,
      ThemeMode.light => AppThemePreference.light,
    };
  }

  static ThemeMode _toThemeMode(AppThemePreference preference) {
    return switch (preference) {
      AppThemePreference.system => ThemeMode.system,
      AppThemePreference.dark => ThemeMode.dark,
      AppThemePreference.light => ThemeMode.light,
    };
  }
}
