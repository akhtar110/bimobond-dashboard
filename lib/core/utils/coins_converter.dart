import 'money_format.dart';

/// Converts coin amounts to fiat using the COINS_PER_PRICE_UNIT setting.
///
/// fiatValue = amountCoins / coinsPerPriceUnit
abstract final class CoinsConverter {
  static double coinsToFiat(
    int amountCoins,
    double coinsPerPriceUnit,
  ) {
    if (coinsPerPriceUnit <= 0) return 0;
    return amountCoins / coinsPerPriceUnit;
  }

  /// e.g. `≈ $250.00`, or null when the rate is unknown/invalid.
  static String? approxFiatLabel(
    num amountCoins,
    double? coinsPerPriceUnit, {
    String currencyCode = 'USD',
    String? locale,
  }) {
    if (coinsPerPriceUnit == null || coinsPerPriceUnit <= 0) return null;
    final fiat = coinsToFiat(amountCoins.round(), coinsPerPriceUnit);
    return '≈ ${MoneyFormat.format(fiat, currencyCode, locale: locale)}';
  }
}
