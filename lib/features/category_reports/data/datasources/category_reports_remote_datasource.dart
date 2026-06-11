import 'package:dio/dio.dart';

import '../../../../core/utils/api_page_parser.dart';
import '../../../user_activity/domain/entities/paginated_page.dart';
import '../../domain/entities/category_report_entities.dart';
import '../models/category_report_models.dart';

abstract class CategoryReportsRemoteDataSource {
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

class CategoryReportsRemoteDataSourceImpl
    implements CategoryReportsRemoteDataSource {
  const CategoryReportsRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<CategoryReportOverviewEntity> getOverview(
    CategoryReportPeriodQuery query,
  ) async {
    final response = await _dio.get(
      '/category-reports/admin/overview',
      queryParameters: query.toQueryParameters(),
    );
    return CategoryReportModels.overviewFromJson(response.data);
  }

  @override
  Future<PaginatedPage<CategoryReportListItemEntity>> getCategories({
    required int page,
    required int limit,
    required CategoryReportsListQuery query,
  }) async {
    final response = await _dio.get(
      '/category-reports/admin/categories',
      queryParameters: {
        'page': page,
        'limit': limit,
        ...query.toQueryParameters(),
      },
    );

    final data = response.data;
    final list = ApiPageParser.extractList(data);
    final meta = ApiPageParser.extractMeta(data);
    final items = list
        .map(CategoryReportModels.listItemFromJson)
        .toList(growable: false);

    return PaginatedPage(
      items: items,
      page: ApiPageParser.intMeta(meta, 'page', fallback: page),
      lastPage: ApiPageParser.intMeta(meta, 'totalPages', fallback: 1),
      total: ApiPageParser.intMeta(meta, 'total', fallback: items.length),
    );
  }

  @override
  Future<CategoryReportDetailEntity> getCategoryDetail({
    required String categoryId,
    required CategoryReportPeriodQuery query,
  }) async {
    final response = await _dio.get(
      '/category-reports/admin/categories/$categoryId',
      queryParameters: query.toQueryParameters(),
    );
    return CategoryReportModels.detailFromJson(response.data);
  }
}
