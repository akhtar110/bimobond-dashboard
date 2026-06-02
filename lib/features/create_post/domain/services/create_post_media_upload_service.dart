import '../create_post_payload_builder.dart';
import '../entities/create_post_entity.dart';
import '../usecases/upload_post_media_usecase.dart';

/// Step 1 of post creation: `POST /posts/upload` — preserves file order.
class CreatePostMediaUploadService {
  const CreatePostMediaUploadService(this._uploadPostMedia);

  final UploadPostMedia _uploadPostMedia;

  Future<CreatePostEntity> uploadPending(
    CreatePostEntity form, {
    void Function(int completed, int total)? onFileProgress,
  }) async {
    final pending = form.localMedia.where((f) => !f.isUploaded).toList();
    if (pending.isEmpty) return form;

    final urlById = <String, String>{};

    // Batch upload (max 10 per request per API).
    for (var offset = 0; offset < pending.length; offset += 10) {
      final batch = pending.skip(offset).take(10).toList();
      final urls = await _uploadPostMedia(batch);
      if (urls.length != batch.length) {
        throw Exception(
          'Upload returned ${urls.length} URLs for ${batch.length} files',
        );
      }
      for (var i = 0; i < batch.length; i++) {
        urlById[batch[i].id] =
            CreatePostPayloadBuilder.normalizeUploadUrl(urls[i]);
        onFileProgress?.call(offset + i + 1, pending.length);
      }
    }

    final updatedLocal = form.localMedia
        .map(
          (f) => urlById.containsKey(f.id)
              ? f.copyWith(uploadedUrl: urlById[f.id])
              : f,
        )
        .toList(growable: false);

    return form.copyWith(localMedia: updatedLocal);
  }
}
