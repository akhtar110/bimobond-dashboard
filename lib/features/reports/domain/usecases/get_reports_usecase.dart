import '../entities/report_entity.dart';
import '../entities/reports_query_params.dart';
import '../repositories/reports_repository.dart';

class GetReports {
  const GetReports(this._repository);
  final ReportsRepository _repository;

  Future<({List<ReportEntity> reports, int total, int lastPage})> call({
    int page = 1,
    int limit = 15,
    String? status,
    String? type,
    String? reporterId,
    String? reportedUserId,
    String? postId,
    String? commentId,
    String? storyId,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy,
    String? sortOrder,
  }) =>
      _repository.getReports(
        page: page,
        limit: limit,
        status: status,
        type: type,
        reporterId: reporterId,
        reportedUserId: reportedUserId,
        postId: postId,
        commentId: commentId,
        storyId: storyId,
        search: search,
        startDate: startDate,
        endDate: endDate,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );

  Future<({List<ReportEntity> reports, int total, int lastPage})> withQuery(
    ReportsQueryParams query,
  ) =>
      _repository.getReportsWithQuery(query);
}
