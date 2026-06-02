import '../entities/category_entity.dart';
import '../repositories/categories_repository.dart';

class UpdateCategory {
  const UpdateCategory(this.repository);
  final CategoriesRepository repository;

  Future<CategoryEntity> call(String id, UpdateCategoryData data) =>
      repository.updateCategory(id, data);
}
