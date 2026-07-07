import '../../../user_activity/domain/entities/paginated_page.dart';
import '../entities/auction_report_entities.dart';
import '../entities/auction_reports_query.dart';
import '../repositories/auction_reports_repository.dart';

class GetAuctionReportsList {
  const GetAuctionReportsList(this._repository);

  final AuctionReportsRepository _repository;

  Future<PaginatedPage<AuctionReportListItem>> call({
    required int page,
    required int limit,
    required AuctionReportsListQuery query,
  }) =>
      _repository.getAuctions(page: page, limit: limit, query: query);
}
