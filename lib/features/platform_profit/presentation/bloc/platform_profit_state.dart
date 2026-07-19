part of 'platform_profit_bloc.dart';

abstract class PlatformProfitState extends Equatable {
  const PlatformProfitState();
  @override
  List<Object?> get props => [];
}

class PlatformProfitInitial extends PlatformProfitState {
  const PlatformProfitInitial();
}

class PlatformProfitLoading extends PlatformProfitState {
  const PlatformProfitLoading();
}

class PlatformProfitLoaded extends PlatformProfitState {
  const PlatformProfitLoaded({
    required this.data,
    required this.preset,
    required this.query,
    this.isRefreshing = false,
  });

  final PlatformProfitEntity data;
  final PlatformProfitRangePreset preset;
  final PlatformProfitQuery query;
  final bool isRefreshing;

  PlatformProfitLoaded copyWith({
    PlatformProfitEntity? data,
    PlatformProfitRangePreset? preset,
    PlatformProfitQuery? query,
    bool? isRefreshing,
  }) {
    return PlatformProfitLoaded(
      data: data ?? this.data,
      preset: preset ?? this.preset,
      query: query ?? this.query,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [data, preset, query, isRefreshing];
}

class PlatformProfitError extends PlatformProfitState {
  const PlatformProfitError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
