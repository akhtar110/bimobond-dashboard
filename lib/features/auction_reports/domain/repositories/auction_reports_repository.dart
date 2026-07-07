import '../../../user_activity/domain/entities/paginated_page.dart';
import '../entities/auction_report_entities.dart';
import '../entities/auction_reports_query.dart';

abstract class AuctionReportsRepository {
  Future<AuctionReportOverviewEntity> getOverview(ReportPeriodQuery query);

  Future<PaginatedPage<AuctionReportListItem>> getAuctions({
    required int page,
    required int limit,
    required AuctionReportsListQuery query,
  });

  Future<AuctionReportDetailEntity> getAuctionDetail({
    required String auctionId,
    required ReportPeriodQuery query,
  });
}
