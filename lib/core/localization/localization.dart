import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;
  late Map<String, dynamic> _localizedValues;

  static const supportedLocales = [Locale('en'), Locale('ar')];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final localizations =
        Localizations.of<AppLocalizations>(context, AppLocalizations);
    if (localizations == null) {
      throw FlutterError('AppLocalizations not found in context');
    }
    return localizations;
  }

  Future<void> load() async {
    final languageCode = Intl.canonicalizedLocale(locale.languageCode);
    final filePath = 'lib/core/localization/app_$languageCode.arb';
    final jsonString = await rootBundle.loadString(filePath);
    _localizedValues = json.decode(jsonString) as Map<String, dynamic>;
  }

  String t(String key) => _localizedValues[key] as String? ?? key;

  /// Returns [fallback] when [key] is missing from the loaded bundle.
  String tOr(String key, String fallback) =>
      _localizedValues[key] as String? ?? fallback;

  /// Replaces `{name}`-style placeholders in localized strings.
  String tArgs(String key, Map<String, String> args) {
    var value = t(key);
    for (final entry in args.entries) {
      value = value.replaceAll('{${entry.key}}', entry.value);
    }
    return value;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.any(
        (supportedLocale) => supportedLocale.languageCode == locale.languageCode,
      );

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localization = AppLocalizations(locale);
    await localization.load();
    return localization;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => true;
}

extension LocalizationX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  String tr(String key, [Map<String, String> args = const {}]) {
    if (args.isEmpty) return l10n.t(key);
    return l10n.tArgs(key, args);
  }

  String trOr(String key, String fallback) => l10n.tOr(key, fallback);

  bool get isRtl => Localizations.localeOf(this).languageCode == 'ar';
}
