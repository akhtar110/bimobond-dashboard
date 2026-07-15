import 'package:intl/intl.dart';

import 'money_format.dart';

/// Formatting helpers for the coins economy.
///
/// Coins are shown everywhere except coin pack store prices, purchase
/// history, and admin money KPIs (use [MoneyFormat] with [currencyCode]).
abstract final class CoinFormat {
  /// Raw purchase volume KPI (may mix currencies) — no symbol.
  static String purchaseVolume(num value, {String? locale}) =>
      _compactNumber(value, locale: locale);

  static String coins(num value, {String? locale}) {
    return '${_compactNumber(value, locale: locale)} coins';
  }

  /// e.g. `500` without suffix — for tables with a coin icon column.
  static String coinsAmount(num value, {String? locale}) {
    return _compactNumber(value, locale: locale);
  }

  /// e.g. `500 coins`, `1.2m coins`
  static String coinsProgress({
    required num current,
    required num target,
    String? locale,
  }) {
    return '${coinsAmount(current, locale: locale)} / ${coinsAmount(target, locale: locale)} coins';
  }

  static String _compactNumber(num value, {String? locale}) {
    final n = value.toDouble();
    if (!n.isFinite) return '$value';

    final abs = n.abs();
    if (abs < 1000) return _formatPlainAmount(n, locale: locale);

    final sign = n < 0 ? '-' : '';
    if (abs >= 1e12) {
      return '$sign${_formatScaled(abs / 1e12)}t';
    }
    if (abs >= 1e6) {
      return '$sign${_formatScaled(abs / 1e6)}m';
    }
    return '$sign${_formatScaled(abs / 1e3)}k';
  }

  static String _formatScaled(double scaled) {
    if (scaled >= 100) return scaled.round().toString();
    final rounded = (scaled * 10).round() / 10;
    if (rounded == rounded.roundToDouble()) {
      return rounded.toInt().toString();
    }
    return rounded.toStringAsFixed(1);
  }

  static String _formatPlainAmount(double n, {String? locale}) {
    if (n == n.roundToDouble()) {
      return NumberFormat.decimalPattern(locale ?? 'en').format(n.toInt());
    }
    return NumberFormat.decimalPattern(locale ?? 'en').format(n);
  }

  /// @deprecated Use [MoneyFormat.format] with [currencyCode].
  static String fiatUsd(num value, {String? locale}) =>
      MoneyFormat.format(value, 'USD', locale: locale);
}
