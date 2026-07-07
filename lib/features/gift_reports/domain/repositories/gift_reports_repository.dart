import '../../../user_activity/domain/entities/paginated_page.dart';
import '../entities/gift_report_entities.dart';

abstract class GiftReportsRepository {
  Future<GiftReportOverviewEntity> getOverview(GiftReportPeriodQuery query);

  Future<PaginatedPage<GiftReportListItemEntity>> getGifts({
    required int page,
    required int limit,
    required GiftReportsListQuery query,
  });

  Future<GiftReportDetailEntity> getGiftDetail({
    required String giftId,
    required GiftReportPeriodQuery query,
  });
}
