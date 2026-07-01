import 'package:dio/dio.dart';

import '../models/active_story_model.dart';

abstract class StoriesRemoteDataSource {
  Future<List<ActiveStoryModel>> getActiveStories();
}

class StoriesRemoteDataSourceImpl implements StoriesRemoteDataSource {
  const StoriesRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<ActiveStoryModel>> getActiveStories() async {
    final response = await _dio.get(
      '/posts/admin/all',
      queryParameters: const {
        'activeStory': 'true',
        'page': 1,
        'limit': 50,
        'sort': 'LATEST',
      },
    );

    final raw = response.data;
    if (raw is! Map<String, dynamic>) {
      return const [];
    }

    final rawList =
        (raw['data'] ?? raw['posts'] ?? raw['videos']) as List? ?? const [];

    return rawList
        .whereType<Map<String, dynamic>>()
        .map(ActiveStoryModel.fromJson)
        .where((story) => story.mediaUrl.isNotEmpty)
        .where((story) => story.postData.isStory)
        .where((story) => story.expiresAt.isAfter(DateTime.now()))
        .toList(growable: false);
  }
}
