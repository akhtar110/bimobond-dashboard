import 'package:equatable/equatable.dart';

/// Known admin economy setting keys.
abstract final class EconomySettingKeys {
  static const auctionCommissionPercent = 'AUCTION_COMMISSION_PERCENT';
  static const coinsPerPriceUnit = 'COINS_PER_PRICE_UNIT';
}

class EconomySettingEntity extends Equatable {
  const EconomySettingEntity({
    required this.key,
    required this.value,
  });

  final String key;
  final String value;

  double? get asDouble => double.tryParse(value);

  @override
  List<Object?> get props => [key, value];
}
