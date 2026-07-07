import '../entities/gift_report_entities.dart';
import '../repositories/gift_reports_repository.dart';

class GetGiftReportDetail {
  const GetGiftReportDetail(this._repository);

  final GiftReportsRepository _repository;

  Future<GiftReportDetailEntity> call({
    required String giftId,
    required GiftReportPeriodQuery query,
  }) =>
      _repository.getGiftDetail(giftId: giftId, query: query);
}
