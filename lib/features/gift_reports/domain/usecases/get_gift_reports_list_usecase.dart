import '../../../user_activity/domain/entities/paginated_page.dart';
import '../entities/gift_report_entities.dart';
import '../repositories/gift_reports_repository.dart';

class GetGiftReportsList {
  const GetGiftReportsList(this._repository);

  final GiftReportsRepository _repository;

  Future<PaginatedPage<GiftReportListItemEntity>> call({
    required int page,
    int limit = 20,
    required GiftReportsListQuery query,
  }) =>
      _repository.getGifts(page: page, limit: limit, query: query);
}
