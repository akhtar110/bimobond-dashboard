import '../entities/category_report_entities.dart';
import '../repositories/category_reports_repository.dart';

class GetCategoryReportsOverview {
  const GetCategoryReportsOverview(this._repository);

  final CategoryReportsRepository _repository;

  Future<CategoryReportOverviewEntity> call(CategoryReportPeriodQuery query) =>
      _repository.getOverview(query);
}
