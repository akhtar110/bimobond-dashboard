import '../create_post_payload_builder.dart';
import '../entities/create_post_entity.dart';
import '../services/create_post_media_upload_service.dart';
import 'create_post_usecase.dart';

/// Orchestrates the 2-step API flow: upload media → `POST /posts`.
class SubmitCreatePost {
  const SubmitCreatePost({
    required CreatePostMediaUploadService uploadService,
    required CreatePost createPost,
  })  : _uploadService = uploadService,
        _createPost = createPost;

  final CreatePostMediaUploadService _uploadService;
  final CreatePost _createPost;

  Future<CreatePostEntity> call({
    required CreatePostEntity form,
    required bool publish,
    void Function(double uploadProgress)? onUploadProgress,
    void Function()? onCreatingPost,
  }) async {
    if (form.localMedia.isEmpty) {
      throw Exception('media_required');
    }

    var working = form.copyWith(
      status: publish ? 'PUBLISHED' : 'DRAFT',
    );

    if (!working.allMediaUploaded) {
      working = await _uploadService.uploadPending(
        working,
        onFileProgress: (done, total) {
          onUploadProgress?.call(done / total);
        },
      );
    }

    if (!working.allMediaUploaded) {
      throw Exception('Media upload incomplete');
    }

    final payload = CreatePostPayloadBuilder.build(working);
    onCreatingPost?.call();
    await _createPost(payload);
    return payload;
  }
}
