import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../domain/entities/categories_admin_list_query.dart';
import '../../domain/entities/category_entity.dart';
import '../models/category_model.dart';

abstract class CategoriesRemoteDataSource {
  Future<List<CategoryModel>> getAllCategories({
    CategoriesAdminListQuery? query,
  });
  Future<CategoryModel> createCategory(CreateCategoryData data);
  Future<CategoryModel> updateCategory(String id, UpdateCategoryData data);
  Future<void> deleteCategory(String id);
}

class CategoriesRemoteDataSourceImpl implements CategoriesRemoteDataSource {
  const CategoriesRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<CategoryModel>> getAllCategories({
    CategoriesAdminListQuery? query,
  }) async {
    final params = query?.toQueryParameters();
    final response = await _dio.get(
      '/categories/admin/all',
      queryParameters: params?.isNotEmpty == true ? params : null,
    );
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
    if (data.iconBytes != null) {
      final response = await _dio.post(
        '/categories',
        data: _multipartBody(
          fields: {
            'name': data.name,
            if (data.description != null && data.description!.isNotEmpty)
              'description': data.description!,
            'isActive': data.isActive,
            'order': data.order,
            if (data.parentId != null) 'parentId': data.parentId!,
          },
          iconBytes: data.iconBytes,
          iconFilename: data.iconFilename,
        ),
      );
      return _parseCategoryResponse(response.data);
    }

    final response = await _dio.post(
      '/categories',
      data: {
        'name': data.name,
        if (data.description != null && data.description!.isNotEmpty)
          'description': data.description,
        if (data.iconUrl != null && data.iconUrl!.trim().isNotEmpty)
          'iconUrl': data.iconUrl!.trim(),
        'isActive': data.isActive,
        'order': data.order,
        if (data.parentId != null) 'parentId': data.parentId,
      },
    );
    return _parseCategoryResponse(response.data);
  }

  @override
  Future<CategoryModel> updateCategory(String id, UpdateCategoryData data) async {
    if (data.iconBytes != null) {
      final fields = <String, dynamic>{
        if (data.name != null) 'name': data.name!,
        if (data.description != null) 'description': data.description!,
        if (data.isActive != null) 'isActive': data.isActive!,
        if (data.order != null) 'order': data.order!,
        if (data.setParentId) 'parentId': data.parentId,
      };
      final response = await _dio.patch(
        '/categories/$id',
        data: _multipartBody(
          fields: fields,
          iconBytes: data.iconBytes,
          iconFilename: data.iconFilename,
        ),
      );
      return _parseCategoryResponse(response.data);
    }

    final body = <String, dynamic>{
      if (data.name != null) 'name': data.name,
      if (data.description != null) 'description': data.description,
      if (data.isActive != null) 'isActive': data.isActive,
      if (data.order != null) 'order': data.order,
      if (data.setParentId) 'parentId': data.parentId,
      if (data.setIconUrl) 'iconUrl': data.iconUrl,
      if (!data.setIconUrl &&
          data.iconUrl != null &&
          data.iconUrl!.trim().isNotEmpty)
        'iconUrl': data.iconUrl!.trim(),
    };
    final response = await _dio.patch('/categories/$id', data: body);
    return _parseCategoryResponse(response.data);
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _dio.delete('/categories/$id');
  }

  FormData _multipartBody({
    required Map<String, dynamic> fields,
    Uint8List? iconBytes,
    String? iconFilename,
  }) {
    final form = FormData();
    for (final entry in fields.entries) {
      final value = entry.value;
      if (value is bool) {
        form.fields.add(MapEntry(entry.key, value ? 'true' : 'false'));
      } else {
        form.fields.add(MapEntry(entry.key, value.toString()));
      }
    }
    if (iconBytes != null) {
      form.files.add(
        MapEntry(
          'icon',
          MultipartFile.fromBytes(
            iconBytes,
            filename: iconFilename ?? 'category-icon.png',
          ),
        ),
      );
    }
    return form;
  }

  CategoryModel _parseCategoryResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      final payload = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data['category'] is Map<String, dynamic>
              ? data['category'] as Map<String, dynamic>
              : data;
      return CategoryModel.fromJson(payload);
    }
    throw Exception('Invalid category response format');
  }
}
