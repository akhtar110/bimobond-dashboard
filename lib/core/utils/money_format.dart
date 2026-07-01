import 'package:intl/intl.dart';

/// Formats real-money amounts using ISO 4217 [currencyCode] — never hardcode `$`.
abstract final class MoneyFormat {
  static String format(
    num amount,
    String currencyCode, {
    String? locale,
  }) {
    final code = currencyCode.trim().isEmpty ? 'USD' : currencyCode.trim();
    return NumberFormat.simpleCurrency(
      name: code,
      locale: locale,
    ).format(amount);
  }

  static String formatOptional(
    num? amount,
    String? currencyCode, {
    String? locale,
    String fallback = '—',
  }) {
    if (amount == null) return fallback;
    return format(amount, currencyCode ?? 'USD', locale: locale);
  }
}
