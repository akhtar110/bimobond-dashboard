import '../../../user_activity/domain/entities/paginated_page.dart';
import '../../domain/entities/post_report_entities.dart';
import '../../domain/entities/post_reports_query.dart';
import '../../domain/repositories/post_reports_repository.dart';
import '../datasources/post_reports_remote_datasource.dart';

class PostReportsRepositoryImpl implements PostReportsRepository {
  const PostReportsRepositoryImpl(this._remote);

  final PostReportsRemoteDataSource _remote;

  @override
  Future<PostReportOverviewEntity> getOverview(ReportPeriodQuery query) =>
      _remote.getOverview(query);

  @override
  Future<PaginatedPage<PostReportListItem>> getPosts({
    required int page,
    required int limit,
    required PostReportsListQuery query,
  }) =>
      _remote.getPosts(page: page, limit: limit, query: query);

  @override
  Future<PostReportDetailEntity> getPostDetail({
    required String postId,
    required ReportPeriodQuery query,
  }) =>
      _remote.getPostDetail(postId: postId, query: query);
}
