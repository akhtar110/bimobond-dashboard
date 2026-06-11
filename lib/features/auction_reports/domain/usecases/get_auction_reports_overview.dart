import '../entities/auction_report_entities.dart';
import '../repositories/auction_reports_repository.dart';

class GetAuctionReportsOverview {
  const GetAuctionReportsOverview(this._repository);

  final AuctionReportsRepository _repository;

  Future<AuctionReportOverviewEntity> call(ReportPeriodQuery query) =>
      _repository.getOverview(query);
}
