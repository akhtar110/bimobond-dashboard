import 'package:flutter/material.dart';

/// Bundled UI fonts (see [pubspec.yaml] `fonts` section).
abstract final class AppFonts {
  static const montserrat = 'Montserrat';
  static const jannat = 'Jannat';

  static String forLocale(Locale locale) =>
      locale.languageCode == 'ar' ? jannat : montserrat;
}
