import '../entities/report_entity.dart';
import '../entities/reports_query_params.dart';

abstract class ReportsRepository {
  /// Returns a page of reports.
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
  });

  Future<({List<ReportEntity> reports, int total, int lastPage})> getReportsWithQuery(
    ReportsQueryParams query,
  );

  Future<ReportEntity> getReportById(String id);

  Future<ReportEntity> updateReportStatus({
    required String id,
    required String status,
  });
}
