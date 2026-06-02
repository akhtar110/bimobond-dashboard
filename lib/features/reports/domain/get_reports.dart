import 'report_entity.dart';
import 'reports_repository.dart';

class GetReports {
  const GetReports(this.repository);
  final ReportsRepository repository;

  Future<List<ReportEntity>> call() => repository.getReports();
}
