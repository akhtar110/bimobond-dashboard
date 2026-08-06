import '../../domain/entities/category_entity.dart';

typedef CategoryFormCallback = void Function({
  CategoryEntity? editing,
  CategoryEntity? parentForNew,
});

typedef CategoryDeleteCallback = void Function(CategoryEntity category);

typedef CategoryToggleStatusCallback = void Function(CategoryEntity category);

