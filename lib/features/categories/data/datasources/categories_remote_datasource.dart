import 'package:dio/dio.dart';

import '../../domain/entities/category_entity.dart';
import '../models/category_model.dart';

abstract class CategoriesRemoteDataSource {
  Future<List<CategoryModel>> getAllCategories();
  Future<CategoryModel> createCategory(CreateCategoryData data);
  Future<CategoryModel> updateCategory(String id, UpdateCategoryData data);
  Future<void> deleteCategory(String id);
}

class CategoriesRemoteDataSourceImpl implements CategoriesRemoteDataSource {
  const CategoriesRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<CategoryModel>> getAllCategories() async {
    final response = await _dio.get('/categories/admin/all');
    final data = response.data;
    final list = data is List
        ? data
        : (data['categories'] ?? data['data'] ?? []) as List;
    return list
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CategoryModel> createCategory(CreateCategoryData data) async {
    final response = await _dio.post(
      '/categories',
      data: {
        'name': data.name,
        if (data.description != null) 'description': data.description,
        'isActive': data.isActive,
        'order': data.order,
      },
    );
    return CategoryModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<CategoryModel> updateCategory(String id, UpdateCategoryData data) async {
    final body = <String, dynamic>{
      if (data.name != null) 'name': data.name,
      if (data.description != null) 'description': data.description,
      if (data.isActive != null) 'isActive': data.isActive,
      if (data.order != null) 'order': data.order,
    };
    final response = await _dio.patch('/categories/$id', data: body);
    return CategoryModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _dio.delete('/categories/$id');
  }
}
