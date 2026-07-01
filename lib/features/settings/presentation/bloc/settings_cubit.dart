import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  SettingsCubit()
    : super(const SettingsState(themeMode: ThemeMode.dark, locale: Locale('en')));

  void switchTheme(bool isDark) {
    final mode = isDark ? ThemeMode.dark : ThemeMode.light;
    if (state.themeMode == mode) return;
    emit(state.copyWith(themeMode: mode));
  }

  void switchLanguage(Locale locale) {
    if (state.locale.languageCode == locale.languageCode) return;
    emit(state.copyWith(locale: locale));
  }
}
