import 'package:flutter/material.dart';

import 'app_fonts.dart';

class AppTheme {
  static final Map<String, ThemeData> _cache = {};

  static ThemeData darkTheme(Locale locale) =>
      _cached(brightness: Brightness.dark, locale: locale);

  static ThemeData lightTheme(Locale locale) =>
      _cached(brightness: Brightness.light, locale: locale);

  static ThemeData _cached({
    required Brightness brightness,
    required Locale locale,
  }) {
    final key = '${brightness.name}_${locale.languageCode}';
    return _cache.putIfAbsent(
      key,
      () => _build(brightness: brightness, locale: locale),
    );
  }

  static ThemeData _build({
    required Brightness brightness,
    required Locale locale,
  }) {
    final isDark = brightness == Brightness.dark;
    final fontFamily = AppFonts.forLocale(locale);
    final scheme = ColorScheme.fromSeed(
      seedColor: Colors.pink,
      brightness: brightness,
    );
    final textTheme = _textTheme(brightness, fontFamily);

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF111318) : const Color(0xFFF5F7FC),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      cardTheme: CardThemeData(
        elevation: isDark ? 8 : 6,
        shadowColor: isDark
            ? Colors.black.withValues(alpha: 0.5)
            : Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: const EdgeInsetsDirectional.only(bottom: 12),
      ),
      dividerTheme: DividerThemeData(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.02),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          textStyle: TextStyle(fontFamily: fontFamily),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          textStyle: TextStyle(fontFamily: fontFamily),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: TextStyle(fontFamily: fontFamily),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: TextStyle(fontFamily: fontFamily),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
      ),
      appBarTheme: AppBarTheme(
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static TextTheme _textTheme(Brightness brightness, String fontFamily) {
    final base = brightness == Brightness.dark
        ? Typography.material2021(platform: TargetPlatform.android).white
        : Typography.material2021(platform: TargetPlatform.android).black;

    return base.apply(fontFamily: fontFamily).copyWith(
          titleLarge: TextStyle(
            fontFamily: fontFamily,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: TextStyle(
            fontFamily: fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            fontFamily: fontFamily,
            fontSize: 15,
          ),
        );
  }
}
