import '../entities/category_entity.dart';
import '../repositories/categories_repository.dart';

class GetAllCategories {
  const GetAllCategories(this.repository);

  final CategoriesRepository repository;

  Future<List<CategoryEntity>> call() => repository.getAllCategories();
}
