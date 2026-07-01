import 'dart:typed_data';

import '../../domain/repositories/video_thumbnail_repository.dart';

class GenerateVideoThumbnailUseCase {
  const GenerateVideoThumbnailUseCase(this._repository);

  final VideoThumbnailRepository _repository;

  Future<Uint8List?> call({
    required Uint8List videoBytes,
    required String fileName,
  }) {
    return _repository.generateThumbnail(
      videoBytes: videoBytes,
      fileName: fileName,
    );
  }
}

class UploadThumbnailUseCase {
  const UploadThumbnailUseCase(this._repository);

  final VideoThumbnailRepository _repository;

  Future<String?> call(Uint8List thumbnailBytes) {
    return _repository.uploadThumbnail(thumbnailBytes);
  }
}
