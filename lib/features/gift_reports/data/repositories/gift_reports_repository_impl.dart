import '../../domain/entities/gift_report_entities.dart';
import '../../domain/repositories/gift_reports_repository.dart';
import '../datasources/gift_reports_remote_datasource.dart';
import '../../../user_activity/domain/entities/paginated_page.dart';

class GiftReportsRepositoryImpl implements GiftReportsRepository {
  const GiftReportsRepositoryImpl(this._remote);

  final GiftReportsRemoteDataSource _remote;

  @override
  Future<GiftReportOverviewEntity> getOverview(GiftReportPeriodQuery query) =>
      _remote.getOverview(query);

  @override
  Future<PaginatedPage<GiftReportListItemEntity>> getGifts({
    required int page,
    required int limit,
    required GiftReportsListQuery query,
  }) =>
      _remote.getGifts(page: page, limit: limit, query: query);

  @override
  Future<GiftReportDetailEntity> getGiftDetail({
    required String giftId,
    required GiftReportPeriodQuery query,
  }) =>
      _remote.getGiftDetail(giftId: giftId, query: query);
}
