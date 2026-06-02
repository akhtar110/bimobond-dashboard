import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/categories_repository.dart';
import '../datasources/categories_remote_datasource.dart';

class CategoriesRepositoryImpl implements CategoriesRepository {
  const CategoriesRepositoryImpl(this._dataSource);

  final CategoriesRemoteDataSource _dataSource;

  @override
  Future<List<CategoryEntity>> getAllCategories() =>
      _dataSource.getAllCategories();

  @override
  Future<CategoryEntity> createCategory(CreateCategoryData data) =>
      _dataSource.createCategory(data);

  @override
  Future<CategoryEntity> updateCategory(String id, UpdateCategoryData data) =>
      _dataSource.updateCategory(id, data);

  @override
  Future<void> deleteCategory(String id) => _dataSource.deleteCategory(id);
}
