import '../../../user_activity/domain/entities/paginated_page.dart';
import '../../domain/entities/category_report_entities.dart';
import '../../domain/repositories/category_reports_repository.dart';
import '../datasources/category_reports_remote_datasource.dart';

class CategoryReportsRepositoryImpl implements CategoryReportsRepository {
  const CategoryReportsRepositoryImpl(this._remote);

  final CategoryReportsRemoteDataSource _remote;

  @override
  Future<CategoryReportOverviewEntity> getOverview(
    CategoryReportPeriodQuery query,
  ) =>
      _remote.getOverview(query);

  @override
  Future<PaginatedPage<CategoryReportListItemEntity>> getCategories({
    required int page,
    required int limit,
    required CategoryReportsListQuery query,
  }) =>
      _remote.getCategories(page: page, limit: limit, query: query);

  @override
  Future<CategoryReportDetailEntity> getCategoryDetail({
    required String categoryId,
    required CategoryReportPeriodQuery query,
  }) =>
      _remote.getCategoryDetail(categoryId: categoryId, query: query);
}
