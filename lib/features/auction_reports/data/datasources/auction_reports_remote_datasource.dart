import 'package:dio/dio.dart';

import '../../../user_activity/domain/entities/paginated_page.dart';
import '../../domain/entities/auction_report_entities.dart';
import '../../domain/entities/auction_reports_query.dart';
import '../models/auction_report_models.dart';

abstract class AuctionReportsRemoteDataSource {
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

class AuctionReportsRemoteDataSourceImpl implements AuctionReportsRemoteDataSource {
  const AuctionReportsRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<AuctionReportOverviewEntity> getOverview(ReportPeriodQuery query) async {
    final response = await _dio.get(
      '/auction-reports/admin/overview',
      queryParameters: query.toQueryParameters(),
    );
    return AuctionReportModels.overviewFromJson(response.data);
  }

  @override
  Future<PaginatedPage<AuctionReportListItem>> getAuctions({
    required int page,
    required int limit,
    required AuctionReportsListQuery query,
  }) async {
    final response = await _dio.get(
      '/auction-reports/admin/auctions',
      queryParameters: query.toQueryParameters(page: page, limit: limit),
    );
    return AuctionReportModels.pageFromJson(response.data);
  }

  @override
  Future<AuctionReportDetailEntity> getAuctionDetail({
    required String auctionId,
    required ReportPeriodQuery query,
  }) async {
    final response = await _dio.get(
      '/auction-reports/admin/auctions/$auctionId',
      queryParameters: query.toQueryParameters(),
    );
    return AuctionReportModels.detailFromJson(response.data);
  }
}
