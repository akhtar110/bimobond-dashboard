import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class AppPreferencesLocalDataSource {
  Future<ThemeMode?> getThemeMode();

  Future<void> saveThemeMode(ThemeMode mode);

  Future<Locale?> getLocale();

  Future<void> saveLocale(Locale locale);
}

class AppPreferencesLocalDataSourceImpl
    implements AppPreferencesLocalDataSource {
  AppPreferencesLocalDataSourceImpl(this._prefs);

  final SharedPreferences _prefs;

  static const _themeModeKey = 'admin_theme_mode';
  static const _localeKey = 'admin_locale';

  @override
  Future<ThemeMode?> getThemeMode() async {
    final value = _prefs.getString(_themeModeKey);
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => null,
    };
  }

  @override
  Future<void> saveThemeMode(ThemeMode mode) {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    return _prefs.setString(_themeModeKey, value);
  }

  @override
  Future<Locale?> getLocale() async {
    final value = _prefs.getString(_localeKey);
    return switch (value) {
      'en' => const Locale('en'),
      'ar' => const Locale('ar'),
      _ => null,
    };
  }

  @override
  Future<void> saveLocale(Locale locale) {
    return _prefs.setString(_localeKey, locale.languageCode);
  }
}
