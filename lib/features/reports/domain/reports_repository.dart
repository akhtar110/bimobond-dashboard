import 'report_entity.dart';

abstract class ReportsRepository {
  Future<List<ReportEntity>> getReports();
  Future<void> resolveReport(String reportId, String action);
}
