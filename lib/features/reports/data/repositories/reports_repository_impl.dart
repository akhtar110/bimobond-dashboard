import '../../domain/entities/report_entity.dart';
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
    String? reportedUserId,
    String? reporterId,
    String? postId,
    String? commentId,
    String? storyId,
    String? search,
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
        reportedUserId: reportedUserId,
        reporterId: reporterId,
        postId: postId,
        commentId: commentId,
        storyId: storyId,
        search: search,
        from: from,
        to: to,
        sortBy: sortBy,
        sortOrder: sortOrder,
        sort: sort,
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
