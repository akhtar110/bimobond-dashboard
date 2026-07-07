import '../entities/category_report_entities.dart';
import '../repositories/category_reports_repository.dart';

class GetCategoryReportDetail {
  const GetCategoryReportDetail(this._repository);

  final CategoryReportsRepository _repository;

  Future<CategoryReportDetailEntity> call({
    required String categoryId,
    required CategoryReportPeriodQuery query,
  }) =>
      _repository.getCategoryDetail(categoryId: categoryId, query: query);
}
