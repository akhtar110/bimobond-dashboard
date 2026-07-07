import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/auction_report_entities.dart';
import '../../domain/usecases/get_auction_report_detail.dart';

part 'auction_report_detail_event.dart';
part 'auction_report_detail_state.dart';

class AuctionReportDetailBloc
    extends Bloc<AuctionReportDetailEvent, AuctionReportDetailState> {
  AuctionReportDetailBloc({required GetAuctionReportDetail getAuctionReportDetail})
      : _getAuctionReportDetail = getAuctionReportDetail,
        super(AuctionReportDetailInitial()) {
    on<LoadAuctionReportDetailEvent>(_onLoad);
    on<ChangeAuctionReportDetailDaysEvent>(_onChangeDays);
    on<RefreshAuctionReportDetailEvent>(_onRefresh);
  }

  final GetAuctionReportDetail _getAuctionReportDetail;

  String? _auctionId;
  int _days = 30;

  Future<void> _onLoad(
    LoadAuctionReportDetailEvent event,
    Emitter<AuctionReportDetailState> emit,
  ) async {
    _auctionId = event.auctionId;
    _days = event.days;
    emit(AuctionReportDetailLoading());
    await _fetch(emit);
  }

  Future<void> _onChangeDays(
    ChangeAuctionReportDetailDaysEvent event,
    Emitter<AuctionReportDetailState> emit,
  ) async {
    _days = event.days;
    final current = state;
    if (current is AuctionReportDetailLoaded) {
      emit(current.copyWith(days: event.days, isRefreshing: true));
    } else {
      emit(AuctionReportDetailLoading());
    }
    await _fetch(emit);
  }

  Future<void> _onRefresh(
    RefreshAuctionReportDetailEvent event,
    Emitter<AuctionReportDetailState> emit,
  ) async {
    final current = state;
    if (current is AuctionReportDetailLoaded) {
      emit(current.copyWith(isRefreshing: true));
    }
    await _fetch(emit);
  }

  Future<void> _fetch(Emitter<AuctionReportDetailState> emit) async {
    final auctionId = _auctionId;
    if (auctionId == null || auctionId.isEmpty) {
      emit(AuctionReportDetailError('Missing auction id'));
      return;
    }

    try {
      final detail = await _getAuctionReportDetail(
        auctionId: auctionId,
        query: ReportPeriodQuery(days: _days),
      );
      emit(AuctionReportDetailLoaded(detail: detail, days: _days));
    } catch (e) {
      emit(AuctionReportDetailError(e.toString()));
    }
  }
}
