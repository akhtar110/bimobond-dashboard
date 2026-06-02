import '../repositories/categories_repository.dart';

class DeleteCategory {
  const DeleteCategory(this.repository);
  final CategoriesRepository repository;

  Future<void> call(String id) => repository.deleteCategory(id);
}
