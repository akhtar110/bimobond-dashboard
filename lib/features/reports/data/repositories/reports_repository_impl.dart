import '../../domain/entities/report_entity.dart';
import '../../domain/entities/reports_query_params.dart';
import '../../domain/repositories/reports_repository.dart';
import '../datasources/reports_remote_datasource.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  const ReportsRepositoryImpl(this._dataSource);

  final ReportsRemoteDataSource _dataSource;

  @override
  Future<({List<ReportEntity> reports, int total, int lastPage})> getReports({
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
      _dataSource.getReports(
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

  @override
  Future<({List<ReportEntity> reports, int total, int lastPage})>
      getReportsWithQuery(ReportsQueryParams query) =>
          getReports(
            page: query.page,
            limit: query.limit,
            status: query.status,
            type: query.type,
            reporterId: query.reporterId,
            reportedUserId: query.reportedUserId,
            postId: query.postId,
            commentId: query.commentId,
            storyId: query.storyId,
            search: query.search,
            startDate: query.startDate,
            endDate: query.endDate,
            sortBy: query.sortBy,
            sortOrder: query.sortOrder,
          );

  @override
  Future<ReportEntity> getReportById(String id) =>
      _dataSource.getReportById(id);

  @override
  Future<ReportEntity> updateReportStatus({
    required String id,
    required String status,
  }) =>
      _dataSource.updateReportStatus(id: id, status: status);
}
