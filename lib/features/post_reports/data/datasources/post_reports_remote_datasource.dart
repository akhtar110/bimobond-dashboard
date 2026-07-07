import 'package:dio/dio.dart';

import '../../../user_activity/domain/entities/paginated_page.dart';
import '../../domain/entities/post_report_entities.dart';
import '../../domain/entities/post_reports_query.dart';
import '../models/post_report_models.dart';

abstract class PostReportsRemoteDataSource {
  Future<PostReportOverviewEntity> getOverview(ReportPeriodQuery query);

  Future<PaginatedPage<PostReportListItem>> getPosts({
    required int page,
    required int limit,
    required PostReportsListQuery query,
  });

  Future<PostReportDetailEntity> getPostDetail({
    required String postId,
    required ReportPeriodQuery query,
  });
}

class PostReportsRemoteDataSourceImpl implements PostReportsRemoteDataSource {
  const PostReportsRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<PostReportOverviewEntity> getOverview(ReportPeriodQuery query) async {
    final response = await _dio.get(
      '/post-reports/admin/overview',
      queryParameters: query.toQueryParameters(),
    );
    return PostReportModels.overviewFromJson(response.data);
  }

  @override
  Future<PaginatedPage<PostReportListItem>> getPosts({
    required int page,
    required int limit,
    required PostReportsListQuery query,
  }) async {
    final response = await _dio.get(
      '/post-reports/admin/posts',
      queryParameters: query.toQueryParameters(page: page, limit: limit),
    );
    return PostReportModels.pageFromJson(response.data);
  }

  @override
  Future<PostReportDetailEntity> getPostDetail({
    required String postId,
    required ReportPeriodQuery query,
  }) async {
    final response = await _dio.get(
      '/post-reports/admin/posts/$postId',
      queryParameters: query.toQueryParameters(),
    );
    return PostReportModels.detailFromJson(response.data);
  }
}
