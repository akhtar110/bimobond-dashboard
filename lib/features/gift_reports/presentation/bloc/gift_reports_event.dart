part of 'gift_reports_bloc.dart';

sealed class GiftReportsEvent {}

class LoadGiftReportsOverviewEvent extends GiftReportsEvent {}

class LoadGiftReportsListEvent extends GiftReportsEvent {
  LoadGiftReportsListEvent({this.refresh = false, this.page});
  final bool refresh;
  final int? page;
}

class GoToGiftReportsPageEvent extends GiftReportsEvent {
  GoToGiftReportsPageEvent(this.page);
  final int page;
}

class LoadMoreGiftReportsEvent extends GiftReportsEvent {}

class UpdateGiftReportsSearchEvent extends GiftReportsEvent {
  UpdateGiftReportsSearchEvent(this.query);
  final String query;
}

class UpdateGiftReportsSortEvent extends GiftReportsEvent {
  UpdateGiftReportsSortEvent(this.sort);
  final GiftReportsSort sort;
}

class UpdateGiftReportsActiveFilterEvent extends GiftReportsEvent {
  UpdateGiftReportsActiveFilterEvent(this.isActive);
  final bool? isActive;
}

class SetGiftReportsDateRangeFilterEvent extends GiftReportsEvent {
  SetGiftReportsDateRangeFilterEvent({required this.fromDate, required this.toDate});
  final DateTime? fromDate;
  final DateTime? toDate;
}

class UpdateGiftReportsPriceRangeFilterEvent extends GiftReportsEvent {
  UpdateGiftReportsPriceRangeFilterEvent({
    required this.minPrice,
    required this.maxPrice,
  });
  final double? minPrice;
  final double? maxPrice;
}

class ChangeGiftReportsDaysEvent extends GiftReportsEvent {
  ChangeGiftReportsDaysEvent(this.days);
  final int days;
}

class RefreshGiftReportsEvent extends GiftReportsEvent {}

class ReapplyGiftReportsFiltersEvent extends GiftReportsEvent {}
