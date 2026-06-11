import '../../../user_activity/domain/entities/paginated_page.dart';
import '../entities/post_report_entities.dart';
import '../entities/post_reports_query.dart';
import '../repositories/post_reports_repository.dart';

class GetPostReportsList {
  const GetPostReportsList(this._repository);

  final PostReportsRepository _repository;

  Future<PaginatedPage<PostReportListItem>> call({
    required int page,
    required int limit,
    required PostReportsListQuery query,
  }) =>
      _repository.getPosts(page: page, limit: limit, query: query);
}
