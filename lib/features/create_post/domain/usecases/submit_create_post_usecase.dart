import '../create_post_payload_builder.dart';
import '../entities/create_post_entity.dart';
import '../services/create_post_media_upload_service.dart';
import '../services/create_post_thumbnail_service.dart';
import '../../../posts/domain/usecases/video_thumbnail_usecases.dart';
import 'create_post_usecase.dart';

/// Orchestrates the 2-step API flow: upload media → thumbnail → `POST /posts`.
class SubmitCreatePost {
  const SubmitCreatePost({
    required CreatePostMediaUploadService uploadService,
    required CreatePostThumbnailService thumbnailService,
    required UploadThumbnailUseCase uploadThumbnail,
    required CreatePost createPost,
  })  : _uploadService = uploadService,
        _thumbnailService = thumbnailService,
        _uploadThumbnail = uploadThumbnail,
        _createPost = createPost;

  final CreatePostMediaUploadService _uploadService;
  final CreatePostThumbnailService _thumbnailService;
  final UploadThumbnailUseCase _uploadThumbnail;
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

    if (!publish &&
        (working.description == null || working.description!.trim().isEmpty)) {
      working = working.copyWith(description: '');
    }

    working = await _thumbnailService.generateIfNeeded(working);

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

    working = await _uploadGeneratedThumbnail(working);

    final payload = CreatePostPayloadBuilder.build(working);
    onCreatingPost?.call();
    await _createPost(payload);
    return payload;
  }

  Future<CreatePostEntity> _uploadGeneratedThumbnail(
    CreatePostEntity form,
  ) async {
    if (!form.hasVideoMedia) return form;

    final existing = form.thumbnailUrl?.trim();
    if (existing != null && existing.isNotEmpty) {
      return form;
    }

    final bytes = form.thumbnailBytes;
    if (bytes == null || bytes.isEmpty) return form;

    final uploaded = await _uploadThumbnail(bytes);
    if (uploaded == null || uploaded.isEmpty) return form;

    return form.copyWith(
      thumbnailUrl: CreatePostPayloadBuilder.normalizeUploadUrl(uploaded),
      clearThumbnailBytes: true,
    );
  }
}
