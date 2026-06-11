import 'package:dio/dio.dart';

import '../../../../core/utils/api_page_parser.dart';
import '../../../user_activity/domain/entities/paginated_page.dart';
import '../../domain/entities/gift_report_entities.dart';
import '../models/gift_report_models.dart';

abstract class GiftReportsRemoteDataSource {
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

class GiftReportsRemoteDataSourceImpl implements GiftReportsRemoteDataSource {
  const GiftReportsRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<GiftReportOverviewEntity> getOverview(
    GiftReportPeriodQuery query,
  ) async {
    final response = await _dio.get(
      '/gift-reports/admin/overview',
      queryParameters: query.toQueryParameters(),
    );
    return GiftReportModels.overviewFromJson(response.data);
  }

  @override
  Future<PaginatedPage<GiftReportListItemEntity>> getGifts({
    required int page,
    required int limit,
    required GiftReportsListQuery query,
  }) async {
    final response = await _dio.get(
      '/gift-reports/admin/gifts',
      queryParameters: {
        'page': page,
        'limit': limit,
        ...query.toQueryParameters(),
      },
    );

    final data = response.data;
    final list = ApiPageParser.extractList(data);
    final meta = ApiPageParser.extractMeta(data);
    final items = list
        .map(GiftReportModels.listItemFromJson)
        .toList(growable: false);

    return PaginatedPage(
      items: items,
      page: ApiPageParser.intMeta(meta, 'page', fallback: page),
      lastPage: ApiPageParser.intMeta(meta, 'totalPages', fallback: 1),
      total: ApiPageParser.intMeta(meta, 'total', fallback: items.length),
    );
  }

  @override
  Future<GiftReportDetailEntity> getGiftDetail({
    required String giftId,
    required GiftReportPeriodQuery query,
  }) async {
    final response = await _dio.get(
      '/gift-reports/admin/gifts/$giftId',
      queryParameters: query.toQueryParameters(),
    );
    return GiftReportModels.detailFromJson(response.data);
  }
}
