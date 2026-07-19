import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/utils/dashboard_permissions.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../domain/entities/platform_profit_entities.dart';
import '../../domain/usecases/platform_profit_usecases.dart';

part 'platform_profit_event.dart';
part 'platform_profit_state.dart';

class PlatformProfitBloc
    extends Bloc<PlatformProfitEvent, PlatformProfitState> {
  PlatformProfitBloc({
    required LoadPlatformProfitUseCase loadPlatformProfit,
    required GetMonetizationAnalyticsUseCase getMonetization,
    required GetGiftRevenueOverviewUseCase getGiftRevenue,
    required GetPromotionRevenueUseCase getPromotionRevenue,
    required List<UserRole> roles,
  })  : _loadPlatformProfit = loadPlatformProfit,
        _getMonetization = getMonetization,
        _getGiftRevenue = getGiftRevenue,
        _getPromotionRevenue = getPromotionRevenue,
        _roles = roles,
        super(const PlatformProfitInitial()) {
    on<LoadPlatformProfit>(_onLoad);
    on<RefreshPlatformProfit>(_onRefresh);
    on<ChangeDateRange>(_onChangeDateRange);
    on<LoadGiftRevenue>(_onLoadGiftRevenue);
    on<LoadPromotionRevenue>(_onLoadPromotionRevenue);
    on<LoadMonetizationAnalytics>(_onLoadMonetization);
  }

  final LoadPlatformProfitUseCase _loadPlatformProfit;
  final GetMonetizationAnalyticsUseCase _getMonetization;
  final GetGiftRevenueOverviewUseCase _getGiftRevenue;
  final GetPromotionRevenueUseCase _getPromotionRevenue;
  final List<UserRole> _roles;

  PlatformProfitRangePreset _preset = PlatformProfitRangePreset.last30Days;
  PlatformProfitQuery _query = const PlatformProfitQuery(days: 30);

  bool get canViewMonetization => canViewMonetizationAnalytics(_roles);
  bool get canViewGiftRevenue => isStaff;
  bool get canViewPromotionRevenue => isStaff;
  bool get isStaff =>
      _roles.contains(UserRole.admin) || _roles.contains(UserRole.moderator);

  Future<void> _onLoad(
    LoadPlatformProfit event,
    Emitter<PlatformProfitState> emit,
  ) async {
    emit(const PlatformProfitLoading());
    await _fetch(emit);
  }

  Future<void> _onRefresh(
    RefreshPlatformProfit event,
    Emitter<PlatformProfitState> emit,
  ) async {
    final current = state;
    if (current is PlatformProfitLoaded) {
      emit(current.copyWith(isRefreshing: true));
    } else {
      emit(const PlatformProfitLoading());
    }
    await _fetch(emit);
  }

  Future<void> _onChangeDateRange(
    ChangeDateRange event,
    Emitter<PlatformProfitState> emit,
  ) async {
    _preset = event.preset;
    _query = event.preset == PlatformProfitRangePreset.custom
        ? PlatformProfitQuery(from: event.from, to: event.to)
        : PlatformProfitQuery(days: event.preset.days);

    final current = state;
    if (current is PlatformProfitLoaded) {
      emit(current.copyWith(
        isRefreshing: true,
        preset: _preset,
        query: _query,
      ));
    } else {
      emit(const PlatformProfitLoading());
    }
    await _fetch(emit);
  }

  Future<void> _fetch(Emitter<PlatformProfitState> emit) async {
    try {
      final data = await _loadPlatformProfit(
        query: _query,
        includeMonetization: canViewMonetization,
        includeGiftRevenue: canViewGiftRevenue,
        includePromotionRevenue: canViewPromotionRevenue,
        includeCoinsSetting: canManageSettings(_roles),
      );
      emit(PlatformProfitLoaded(
        data: data,
        preset: _preset,
        query: _query,
      ));
    } catch (e) {
      emit(PlatformProfitError(e.toString()));
    }
  }

  Future<void> _onLoadGiftRevenue(
    LoadGiftRevenue event,
    Emitter<PlatformProfitState> emit,
  ) async {
    final current = state;
    if (current is! PlatformProfitLoaded || !canViewGiftRevenue) return;
    emit(current.copyWith(isRefreshing: true));
    try {
      final giftRevenue = await _getGiftRevenue(_query);
      emit(current.copyWith(
        data: current.data.copyWith(giftRevenue: giftRevenue),
        isRefreshing: false,
      ));
    } catch (e) {
      emit(PlatformProfitError(e.toString()));
    }
  }

  Future<void> _onLoadPromotionRevenue(
    LoadPromotionRevenue event,
    Emitter<PlatformProfitState> emit,
  ) async {
    final current = state;
    if (current is! PlatformProfitLoaded || !canViewPromotionRevenue) return;
    emit(current.copyWith(isRefreshing: true));
    try {
      final promotionRevenue = await _getPromotionRevenue();
      emit(current.copyWith(
        data: current.data.copyWith(promotionRevenue: promotionRevenue),
        isRefreshing: false,
      ));
    } catch (e) {
      emit(PlatformProfitError(e.toString()));
    }
  }

  Future<void> _onLoadMonetization(
    LoadMonetizationAnalytics event,
    Emitter<PlatformProfitState> emit,
  ) async {
    final current = state;
    if (current is! PlatformProfitLoaded || !canViewMonetization) return;
    emit(current.copyWith(isRefreshing: true));
    try {
      final monetization = await _getMonetization(_query);
      emit(current.copyWith(
        data: current.data.copyWith(monetization: monetization),
        isRefreshing: false,
      ));
    } catch (e) {
      emit(PlatformProfitError(e.toString()));
    }
  }
}
