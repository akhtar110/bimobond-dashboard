import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/gift_report_entities.dart';
import '../../domain/usecases/get_gift_report_detail_usecase.dart';

part 'gift_report_detail_event.dart';
part 'gift_report_detail_state.dart';

class GiftReportDetailBloc
    extends Bloc<GiftReportDetailEvent, GiftReportDetailState> {
  GiftReportDetailBloc({required GetGiftReportDetail getDetail})
      : _getDetail = getDetail,
        super(GiftReportDetailInitial()) {
    on<LoadGiftReportDetailEvent>(_onLoad);
    on<ChangeGiftReportDetailDaysEvent>(_onChangeDays);
    on<RefreshGiftReportDetailEvent>(_onRefresh);
  }

  final GetGiftReportDetail _getDetail;

  String? _giftId;
  int _days = 30;

  Future<void> _onLoad(
    LoadGiftReportDetailEvent event,
    Emitter<GiftReportDetailState> emit,
  ) async {
    _giftId = event.giftId;
    _days = event.days;
    emit(GiftReportDetailLoading());
    await _fetch(emit);
  }

  Future<void> _onChangeDays(
    ChangeGiftReportDetailDaysEvent event,
    Emitter<GiftReportDetailState> emit,
  ) async {
    _days = event.days;
    final current = state;
    if (current is GiftReportDetailLoaded) {
      emit(current.copyWith(days: _days, isRefreshing: true));
    }
    await _fetch(emit);
  }

  Future<void> _onRefresh(
    RefreshGiftReportDetailEvent event,
    Emitter<GiftReportDetailState> emit,
  ) async {
    final current = state;
    if (current is GiftReportDetailLoaded) {
      emit(current.copyWith(isRefreshing: true));
    }
    await _fetch(emit);
  }

  Future<void> _fetch(Emitter<GiftReportDetailState> emit) async {
    final giftId = _giftId;
    if (giftId == null || giftId.isEmpty) {
      emit(GiftReportDetailError('Missing gift id'));
      return;
    }

    try {
      final detail = await _getDetail(
        giftId: giftId,
        query: GiftReportPeriodQuery(days: _days),
      );
      emit(
        GiftReportDetailLoaded(
          detail: detail,
          days: _days,
          isRefreshing: false,
        ),
      );
    } catch (e) {
      emit(GiftReportDetailError(e.toString()));
    }
  }
}
