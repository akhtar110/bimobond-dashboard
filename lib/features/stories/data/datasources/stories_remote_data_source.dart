import 'package:dio/dio.dart';

import '../../domain/entities/story_entity.dart';
import '../models/story_model.dart';

abstract class StoriesRemoteDataSource {
  Future<PaginatedStoriesModel> getStories(StoryQuery query);

  Future<StoryModel> updateStory(String id, UpdateStoryRequestModel body);

  Future<bool> deleteStory(String id);
}

class StoriesRemoteDataSourceImpl implements StoriesRemoteDataSource {
  const StoriesRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<PaginatedStoriesModel> getStories(StoryQuery query) async {
    final params = <String, dynamic>{
      'page': query.page,
      'limit': query.limit,
      if (query.search != null && query.search!.trim().isNotEmpty)
        'search': query.search!.trim(),
      if (query.status != null && query.status!.isNotEmpty)
        'status': query.status,
      if (query.privacyStatus != null && query.privacyStatus!.isNotEmpty)
        'privacyStatus': query.privacyStatus,
      if (query.activeOnly == true) 'activeOnly': 'true',
      if (query.userId != null && query.userId!.trim().isNotEmpty)
        'userId': query.userId!.trim(),
    };

    final response = await _dio.get(
      '/stories/admin/all',
      queryParameters: params,
    );

    final raw = response.data;
    if (raw is! Map<String, dynamic>) {
      return PaginatedStoriesModel(
        stories: const [],
        total: 0,
        page: 1,
        limit: query.limit,
        totalPages: 1,
      );
    }

    return PaginatedStoriesModel.fromJson(raw);
  }

  @override
  Future<StoryModel> updateStory(
    String id,
    UpdateStoryRequestModel body,
  ) async {
    final response = await _dio.patch(
      '/stories/admin/$id',
      data: body.toJson(),
    );
    return _parseStory(response.data);
  }

  @override
  Future<bool> deleteStory(String id) async {
    await _dio.delete('/stories/admin/$id');
    return true;
  }

  StoryModel _parseStory(dynamic data) {
    if (data is Map<String, dynamic>) {
      final payload = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data['story'] is Map<String, dynamic>
              ? data['story'] as Map<String, dynamic>
              : data;
      return StoryModel.fromJson(payload);
    }
    throw DioException(
      requestOptions: RequestOptions(path: '/stories/admin'),
      message: 'Invalid story response format',
    );
  }
}
