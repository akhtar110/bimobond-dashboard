import 'dart:convert';

import 'package:flutter/foundation.dart';
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

  static final Map<String, Map<String, dynamic>> _bundleCache = {};

  /// Loads all supported locale bundles into memory so switching is instant.
  static Future<void> preloadBundles() async {
    for (final locale in supportedLocales) {
      await AppLocalizations(locale).load();
    }
  }

  static AppLocalizations of(BuildContext context) {
    final localizations =
        Localizations.of<AppLocalizations>(context, AppLocalizations);
    if (localizations == null) {
      throw FlutterError('AppLocalizations not found in context');
    }
    return localizations;
  }

  /// Synchronous access to preloaded strings (no asset I/O).
  static AppLocalizations ofLocale(Locale locale) {
    final localization = AppLocalizations(locale);
    final languageCode = Intl.canonicalizedLocale(locale.languageCode);
    final bundle = _bundleCache[languageCode] ?? _bundleCache['en'];
    localization._localizedValues = bundle ?? const <String, dynamic>{};
    return localization;
  }

  Future<void> load() async {
    final languageCode = Intl.canonicalizedLocale(locale.languageCode);
    final cached = _bundleCache[languageCode];
    if (cached != null && !kDebugMode) {
      _localizedValues = cached;
      return;
    }

    final filePath = 'lib/core/localization/app_$languageCode.arb';
    final jsonString = await rootBundle.loadString(filePath);
    final bundle = json.decode(jsonString) as Map<String, dynamic>;
    _bundleCache[languageCode] = bundle;
    _localizedValues = bundle;
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
  bool shouldReload(_AppLocalizationsDelegate old) => kDebugMode;
}

extension LocalizationX on BuildContext {
  /// Resolves strings from the effective locale (including [Localizations.override]).
  AppLocalizations get l10n =>
      AppLocalizations.ofLocale(Localizations.localeOf(this));

  String tr(String key, [Map<String, String> args = const {}]) {
    if (args.isEmpty) return l10n.t(key);
    return l10n.tArgs(key, args);
  }

  String trOr(String key, String fallback) => l10n.tOr(key, fallback);

  bool get isRtl => Localizations.localeOf(this).languageCode == 'ar';
}
