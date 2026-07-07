import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/app_preferences_local_datasource.dart';

class SettingsState {
  const SettingsState({required this.themeMode, required this.locale});

  final ThemeMode themeMode;
  final Locale locale;

  SettingsState copyWith({ThemeMode? themeMode, Locale? locale}) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._preferences)
    : super(const SettingsState(themeMode: ThemeMode.dark, locale: Locale('en')));

  final AppPreferencesLocalDataSource _preferences;

  Future<void> load() async {
    final savedThemeMode = await _preferences.getThemeMode();
    final savedLocale = await _preferences.getLocale();

    final themeMode = savedThemeMode ?? state.themeMode;
    final locale = savedLocale ?? state.locale;

    if (themeMode == state.themeMode && locale == state.locale) return;
    emit(SettingsState(themeMode: themeMode, locale: locale));
  }

  void switchThemeMode(ThemeMode mode) {
    if (state.themeMode == mode) return;
    emit(state.copyWith(themeMode: mode));
    _preferences.saveThemeMode(mode);
  }

  void switchTheme(bool isDark) {
    switchThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  void switchLanguage(Locale locale) {
    if (state.locale.languageCode == locale.languageCode) return;
    emit(state.copyWith(locale: locale));
    _preferences.saveLocale(locale);
  }
}
