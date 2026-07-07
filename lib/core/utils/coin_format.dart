import 'package:intl/intl.dart';

import 'money_format.dart';

/// Formatting helpers for the coins economy.
///
/// Coins are shown everywhere except coin pack store prices, purchase
/// history, and admin money KPIs (use [MoneyFormat] with [currencyCode]).
abstract final class CoinFormat {
  static NumberFormat _compact([String? locale]) =>
      NumberFormat.compact(locale: locale ?? 'en');

  /// @deprecated Use [MoneyFormat.format] with [currencyCode].
  static String fiatUsd(num value, {String? locale}) =>
      MoneyFormat.format(value, 'USD', locale: locale);

  /// Raw purchase volume KPI (may mix currencies) — no symbol.
  static String purchaseVolume(num value, {String? locale}) =>
      NumberFormat.decimalPattern(locale ?? 'en').format(value);
  static String coins(num value, {String? locale}) {
    final n = value.toDouble();
    final formatted =
        n.abs() >= 1000 ? _compact(locale).format(n) : _formatCoinAmount(n);
    return '$formatted coins';
  }

  /// e.g. `500` without suffix — for tables with a coin icon column.
  static String coinsAmount(num value, {String? locale}) {
    final n = value.toDouble();
    return n.abs() >= 1000 ? _compact(locale).format(n) : _formatCoinAmount(n);
  }

  /// e.g. `500 coins`, `1.2K coins`
  static String coinsProgress({
    required num current,
    required num target,
    String? locale,
  }) {
    return '${coinsAmount(current, locale: locale)} / ${coinsAmount(target, locale: locale)} coins';
  }

  static String _formatCoinAmount(double n) {
    if (n == n.roundToDouble()) return n.toInt().toString();
    return n.toStringAsFixed(n.truncateToDouble() == n ? 0 : 2);
  }
}
