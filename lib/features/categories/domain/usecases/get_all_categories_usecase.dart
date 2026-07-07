import '../entities/categories_admin_list_query.dart';
import '../entities/category_entity.dart';
import '../repositories/categories_repository.dart';

class GetAllCategories {
  const GetAllCategories(this.repository);

  final CategoriesRepository repository;

  Future<List<CategoryEntity>> call({CategoriesAdminListQuery? query}) =>
      repository.getAllCategories(query: query);
}
