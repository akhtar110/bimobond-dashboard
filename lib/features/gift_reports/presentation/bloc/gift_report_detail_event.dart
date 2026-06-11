part of 'gift_report_detail_bloc.dart';

sealed class GiftReportDetailEvent {}

class LoadGiftReportDetailEvent extends GiftReportDetailEvent {
  LoadGiftReportDetailEvent({required this.giftId, this.days = 30});
  final String giftId;
  final int days;
}

class ChangeGiftReportDetailDaysEvent extends GiftReportDetailEvent {
  ChangeGiftReportDetailDaysEvent(this.days);
  final int days;
}

class RefreshGiftReportDetailEvent extends GiftReportDetailEvent {}
