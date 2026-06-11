import '../entities/auction_report_entities.dart';
import '../repositories/auction_reports_repository.dart';

class GetAuctionReportDetail {
  const GetAuctionReportDetail(this._repository);

  final AuctionReportsRepository _repository;

  Future<AuctionReportDetailEntity> call({
    required String auctionId,
    required ReportPeriodQuery query,
  }) =>
      _repository.getAuctionDetail(auctionId: auctionId, query: query);
}
