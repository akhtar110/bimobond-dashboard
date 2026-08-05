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
    String? userId,
    String? reporterId,
    String? reportedUserId,
    String? postId,
    String? commentId,
    String? storyId,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? from,
    DateTime? to,
    String? sortBy,
    String? sortOrder,
    String? sort,
  }) =>
      _repository.getReports(
        page: page,
        limit: limit,
        status: status,
        type: type,
        userId: userId,
        reporterId: reporterId,
        reportedUserId: reportedUserId,
        postId: postId,
        commentId: commentId,
        storyId: storyId,
        search: search,
        startDate: startDate,
        endDate: endDate,
        from: from,
        to: to,
        sortBy: sortBy,
        sortOrder: sortOrder,
        sort: sort,
      );

  Future<({List<ReportEntity> reports, int total, int lastPage})> withQuery(
    ReportsQueryParams query,
  ) =>
      _repository.getReportsWithQuery(query);
}
