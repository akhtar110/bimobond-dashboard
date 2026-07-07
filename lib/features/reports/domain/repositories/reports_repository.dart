import '../entities/report_entity.dart';

abstract class ReportsRepository {
  /// Returns a page of reports.
  ///
  /// [type]   — filter by target kind: `post`, `user`, or `comment` (null = all).
  /// [status] — filter by resolution state: `PENDING`, `RESOLVED`, or `DISMISSED` (null = all).
  Future<({List<ReportEntity> reports, int total, int lastPage})> getReports({
    int page = 1,
    int limit = 15,
    String? status,
    String? type,
  });

  Future<ReportEntity> getReportById(String id);

  Future<ReportEntity> updateReportStatus({
    required String id,
    required String status,
  });
}
