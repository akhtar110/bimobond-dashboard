import '../entities/categories_admin_list_query.dart';
import '../entities/category_entity.dart';

abstract class CategoriesRepository {
  Future<List<CategoryEntity>> getAllCategories({
    CategoriesAdminListQuery? query,
  });
  Future<CategoryEntity> createCategory(CreateCategoryData data);
  Future<CategoryEntity> updateCategory(String id, UpdateCategoryData data);
  Future<void> deleteCategory(String id);
}
