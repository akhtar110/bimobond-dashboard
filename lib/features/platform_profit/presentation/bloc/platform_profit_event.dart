part of 'platform_profit_bloc.dart';

abstract class PlatformProfitEvent extends Equatable {
  const PlatformProfitEvent();
  @override
  List<Object?> get props => [];
}

/// Initial load (all streams in parallel).
class LoadPlatformProfit extends PlatformProfitEvent {
  const LoadPlatformProfit();
}

/// Reload keeping current data on screen (shows a refresh indicator).
class RefreshPlatformProfit extends PlatformProfitEvent {
  const RefreshPlatformProfit();
}

/// Change the reporting period (preset or custom from/to range).
class ChangeDateRange extends PlatformProfitEvent {
  const ChangeDateRange({
    required this.preset,
    this.from,
    this.to,
  });

  final PlatformProfitRangePreset preset;
  final DateTime? from;
  final DateTime? to;

  @override
  List<Object?> get props => [preset, from, to];
}

/// Reload only the gift revenue stream.
class LoadGiftRevenue extends PlatformProfitEvent {
  const LoadGiftRevenue();
}

/// Reload only the promotion revenue stream.
class LoadPromotionRevenue extends PlatformProfitEvent {
  const LoadPromotionRevenue();
}

/// Reload only the monetization analytics stream.
class LoadMonetizationAnalytics extends PlatformProfitEvent {
  const LoadMonetizationAnalytics();
}
