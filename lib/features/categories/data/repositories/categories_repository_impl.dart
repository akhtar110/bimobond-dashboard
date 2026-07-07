import '../../domain/entities/categories_admin_list_query.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/categories_repository.dart';
import '../datasources/categories_remote_datasource.dart';

class CategoriesRepositoryImpl implements CategoriesRepository {
  const CategoriesRepositoryImpl(this._dataSource);

  final CategoriesRemoteDataSource _dataSource;

  @override
  Future<List<CategoryEntity>> getAllCategories({
    CategoriesAdminListQuery? query,
  }) =>
      _dataSource.getAllCategories(query: query);

  @override
  Future<CategoryEntity> createCategory(CreateCategoryData data) =>
      _dataSource.createCategory(data);

  @override
  Future<CategoryEntity> updateCategory(String id, UpdateCategoryData data) =>
      _dataSource.updateCategory(id, data);

  @override
  Future<void> deleteCategory(String id) => _dataSource.deleteCategory(id);
}
