import '../../../user_activity/domain/entities/paginated_page.dart';
import '../../domain/entities/auction_report_entities.dart';
import '../../domain/entities/auction_reports_query.dart';
import '../../domain/repositories/auction_reports_repository.dart';
import '../datasources/auction_reports_remote_datasource.dart';

class AuctionReportsRepositoryImpl implements AuctionReportsRepository {
  const AuctionReportsRepositoryImpl(this._remote);

  final AuctionReportsRemoteDataSource _remote;

  @override
  Future<AuctionReportOverviewEntity> getOverview(ReportPeriodQuery query) =>
      _remote.getOverview(query);

  @override
  Future<PaginatedPage<AuctionReportListItem>> getAuctions({
    required int page,
    required int limit,
    required AuctionReportsListQuery query,
  }) =>
      _remote.getAuctions(page: page, limit: limit, query: query);

  @override
  Future<AuctionReportDetailEntity> getAuctionDetail({
    required String auctionId,
    required ReportPeriodQuery query,
  }) =>
      _remote.getAuctionDetail(auctionId: auctionId, query: query);
}
