import 'dart:typed_data';

import '../../../create_post/domain/entities/local_media_file.dart';
import '../../../create_post/domain/repositories/create_post_repository.dart';
import '../../domain/repositories/video_thumbnail_repository.dart';
import '../datasources/video_thumbnail_local_data_source.dart';

class VideoThumbnailRepositoryImpl implements VideoThumbnailRepository {
  VideoThumbnailRepositoryImpl(
    this._localDataSource,
    this._createPostRepository,
  );

  final VideoThumbnailLocalDataSource _localDataSource;
  final CreatePostRepository _createPostRepository;

  @override
  Future<Uint8List?> generateThumbnail({
    required Uint8List videoBytes,
    required String fileName,
  }) {
    return _localDataSource.generateFromVideoBytes(
      videoBytes: videoBytes,
      fileName: fileName,
    );
  }

  @override
  Future<String?> uploadThumbnail(Uint8List thumbnailBytes) async {
    if (thumbnailBytes.isEmpty) return null;

    final file = LocalMediaFile(
      id: 'thumbnail_${DateTime.now().microsecondsSinceEpoch}',
      name: 'thumbnail.jpg',
      bytes: thumbnailBytes,
      mediaType: 'IMAGE',
    );

    final urls = await _createPostRepository.uploadMediaFiles([file]);
    if (urls.isEmpty) return null;
    return urls.first;
  }
}
