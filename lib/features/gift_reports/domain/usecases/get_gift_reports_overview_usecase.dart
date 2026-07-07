import '../entities/gift_report_entities.dart';
import '../repositories/gift_reports_repository.dart';

class GetGiftReportsOverview {
  const GetGiftReportsOverview(this._repository);

  final GiftReportsRepository _repository;

  Future<GiftReportOverviewEntity> call(GiftReportPeriodQuery query) =>
      _repository.getOverview(query);
}
