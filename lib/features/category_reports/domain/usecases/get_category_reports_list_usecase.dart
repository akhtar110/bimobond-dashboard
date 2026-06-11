import '../../../user_activity/domain/entities/paginated_page.dart';
import '../entities/category_report_entities.dart';
import '../repositories/category_reports_repository.dart';

class GetCategoryReportsList {
  const GetCategoryReportsList(this._repository);

  final CategoryReportsRepository _repository;

  Future<PaginatedPage<CategoryReportListItemEntity>> call({
    required int page,
    int limit = 20,
    required CategoryReportsListQuery query,
  }) =>
      _repository.getCategories(page: page, limit: limit, query: query);
}
