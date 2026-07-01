import '../../domain/entities/create_post_entity.dart';
import '../../../posts/domain/usecases/video_thumbnail_usecases.dart';

/// Generates a post-level thumbnail from the first local video file.
class CreatePostThumbnailService {
  const CreatePostThumbnailService(this._generateThumbnail);

  final GenerateVideoThumbnailUseCase _generateThumbnail;

  LocalMediaFile? firstVideoFile(CreatePostEntity form) {
    for (final file in form.localMedia) {
      if (file.mediaType == 'VIDEO') return file;
    }
    return null;
  }

  bool needsGeneratedThumbnail(CreatePostEntity form) {
    if (firstVideoFile(form) == null) return false;
    if (form.thumbnailUrl != null && form.thumbnailUrl!.isNotEmpty) {
      return false;
    }
    return form.thumbnailBytes == null || form.thumbnailBytes!.isEmpty;
  }

  Future<CreatePostEntity> generateIfNeeded(CreatePostEntity form) async {
    final video = firstVideoFile(form);
    if (video == null) return form;
    if (!needsGeneratedThumbnail(form)) return form;

    final bytes = await _generateThumbnail(
      videoBytes: video.bytes,
      fileName: video.name,
    );
    if (bytes == null || bytes.isEmpty) return form;

    return form.copyWith(thumbnailBytes: bytes);
  }
}
