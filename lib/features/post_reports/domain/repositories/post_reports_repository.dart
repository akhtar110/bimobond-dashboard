import '../../../user_activity/domain/entities/paginated_page.dart';
import '../entities/post_report_entities.dart';
import '../entities/post_reports_query.dart';

abstract class PostReportsRepository {
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
