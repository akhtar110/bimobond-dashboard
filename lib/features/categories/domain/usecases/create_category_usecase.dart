import '../entities/category_entity.dart';
import '../repositories/categories_repository.dart';

class CreateCategory {
  const CreateCategory(this.repository);
  final CategoriesRepository repository;

  Future<CategoryEntity> call(CreateCategoryData data) =>
      repository.createCategory(data);
}
