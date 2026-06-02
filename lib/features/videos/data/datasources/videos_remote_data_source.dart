import 'package:dio/dio.dart';
import '../../domain/entities/video_entity.dart';
import '../models/video_model.dart';

abstract class VideosRemoteDataSource {
  Future<List<VideoModel>> getVideos({
    required int page,
    required int limit,
    required VideoFilter filter,
    String? userId,
  });
  Future<void> deleteVideo(String videoId);
}

class VideosRemoteDataSourceImpl implements VideosRemoteDataSource {
  final Dio _dio;

  VideosRemoteDataSourceImpl(this._dio);

  @override
  Future<List<VideoModel>> getVideos({
    required int page,
    required int limit,
    required VideoFilter filter,
    String? userId,
  }) async {
    final path = userId != null ? '/posts/admin/all' : '/videos';
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      'filter': filter.name.toUpperCase(),
    };
    if (userId != null) {
      queryParams['userId'] = userId;
    }
    
    final response = await _dio.get(
      path,
      queryParameters: queryParams,
    );

    final data = response.data;
    print('Videos response data: $data');
    if (data is Map<String, dynamic>) {
      final videosList = (data['posts'] ?? data['data'] ?? data['videos']) as List?;
      if (videosList == null) {
        return [];
      }
      print('videosList length: ${videosList.length}');
      return videosList.map((e) => VideoModel.fromJson(e)).toList();
    } else if (data is List) {
      return data.map((e) => VideoModel.fromJson(e)).toList();
    } else {
      throw Exception('Unexpected response format for videos');
    }
  }

  @override
  Future<void> deleteVideo(String videoId) async {
    await _dio.delete('/videos/$videoId');
  }
}

class MockVideosRemoteDataSource implements VideosRemoteDataSource {
  final List<VideoModel> _videos = List.generate(90, (index) {
    final i = index + 1;
    return VideoModel(
      id: 'video_$i',
      thumbnailUrl: 'https://picsum.photos/seed/v$i/600/900',
      ownerName: 'Creator $i',
      reportCount: i % 8,
      isReported: i % 6 == 0,
      isTrending: i % 3 == 0,
      isNew: i <= 20,
    );
  });

  @override
  Future<void> deleteVideo(String videoId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _videos.removeWhere((v) => v.id == videoId);
  }

  @override
  Future<List<VideoModel>> getVideos({
    required int page,
    required int limit,
    required VideoFilter filter,
    String? userId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    Iterable<VideoModel> list = _videos;
    switch (filter) {
      case VideoFilter.reported:
        list = list.where((v) => v.isReported);
      case VideoFilter.trending:
        list = list.where((v) => v.isTrending);
      case VideoFilter.newest:
        list = list.where((v) => v.isNew);
      case VideoFilter.all:
        break;
    }
    if (userId != null) {
      list = list.where((v) => v.ownerName.contains(userId) || v.id.contains(userId));
    }
    final start = (page - 1) * limit;
    if (start >= list.length) return [];
    return list.skip(start).take(limit).toList();
  }
}
