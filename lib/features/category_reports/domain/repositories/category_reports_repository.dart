import '../../../user_activity/domain/entities/paginated_page.dart';
import '../entities/category_report_entities.dart';

abstract class CategoryReportsRepository {
  Future<CategoryReportOverviewEntity> getOverview(
    CategoryReportPeriodQuery query,
  );

  Future<PaginatedPage<CategoryReportListItemEntity>> getCategories({
    required int page,
    required int limit,
    required CategoryReportsListQuery query,
  });

  Future<CategoryReportDetailEntity> getCategoryDetail({
    required String categoryId,
    required CategoryReportPeriodQuery query,
  });
}
